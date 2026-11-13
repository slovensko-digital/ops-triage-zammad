# Hands over the work of an agent (volunteer) who stops working for us to other agents.
#
# New portal tickets get their group and owner from the 700 routing triggers ("700 - Priradenie podnetu skupine
# <municipality> <agent name>", created by the portal's responsible_subjects:activate_basic). The handover works by
# group: a trigger moves as a whole, never split, and the tickets move with the group they are in.
#
#   1. report             lists the triggers routing to the old owner and the tickets they own, by group,
#   2. reassign_triggers! points the triggers to the new owner, so no new tickets reach the old owner,
#   3. reassign_tickets!  moves the old owner's tickets to the new owner, closed ones too: a closed ticket can be
#                         reopened and the new owner is then in charge of it.
#
# A group's tickets cannot be moved while an active trigger still routes tickets to the group and the old owner.
# The new owner gets full access to the groups, the same access the portal gives the agent when it activates a
# municipality. Tickets move silently: no notifications to the new owner, no triggers.
#
# Both reassign methods only print the plan unless called with dry_run: false. Pass groups: to split the old owner's
# groups between several new owners, without it all of them go to the one new owner. A group is named with its
# parents, the way the report shows it: "Bratislava / Devín". An unknown name raises ArgumentError.
#
#   h = Ops::OwnerHandover.new('old@example.org')
#   h.report
#   h.reassign_triggers!(to: 'new@example.org', groups: ['Pezinok', 'Malacky'])
#   h.reassign_triggers!(to: 'new@example.org', groups: ['Pezinok', 'Malacky'], dry_run: false)
#   h.reassign_tickets!(to: 'new@example.org', groups: ['Pezinok', 'Malacky'], dry_run: false)
#
# Ticket ids are listed newest first (created_at), only the first TICKET_IDS_SHOWN of them unless all_ids: true.
#
# The same from the shell: rake ops:owner_handover:{report,triggers,tickets}, see lib/tasks/ops/owner_handover.rake.
class Ops::OwnerHandover
  GROUP_SEPARATOR = ' / '.freeze
  TICKET_IDS_SHOWN = 10

  attr_reader :old_owner

  # "12, 11, 10, ... (245 more)" of [id, created_at] rows, the newest first
  def self.ticket_ids(rows, all: false)
    ids = rows.sort_by { |id, created_at| [created_at, id] }.reverse.map(&:first)
    return ids.join(', ') if all || ids.size <= TICKET_IDS_SHOWN

    "#{ids.first(TICKET_IDS_SHOWN).join(', ')}, ... (#{ids.size - TICKET_IDS_SHOWN} more)"
  end

  def initialize(old_owner_email, out: $stdout, all_ids: false)
    @old_owner = find_agent!(old_owner_email)
    @out = out
    @all_ids = all_ids
  end

  # triggers setting the old owner as the ticket owner, the 700 routing triggers and any other
  def triggers(groups: nil)
    selected = Trigger.order(:name).select { |trigger| owner_id_set_by(trigger) == old_owner.id }
    return selected unless groups

    ids = find_groups!(groups).map(&:id)
    selected.select { |trigger| ids.include?(trigger_group_id(trigger)) }
  end

  def tickets(groups: nil)
    scope = Ticket.where(owner_id: old_owner.id)
    scope = scope.where(group_id: find_groups!(groups).map(&:id)) if groups
    scope.order(:id)
  end

  def report
    all_triggers = triggers
    say "Old owner: #{describe(old_owner)}"
    say ''

    say "Triggers setting the old owner as the ticket owner (#{all_triggers.size}):"
    all_triggers.each do |trigger|
      say "  ##{trigger.id} #{trigger.active ? 'active' : 'INACTIVE'} | group #{group_name(trigger_group_id(trigger))} | " \
          "municipalities #{trigger_municipalities(trigger).inspect} | #{trigger.name}"
    end
    other = other_triggers_mentioning_old_owner(all_triggers)
    if other.any?
      say ''
      say 'Other triggers mentioning the old owner, check them by hand:'
      other.each { |trigger| say "  ##{trigger.id} #{trigger.name}" }
    end

    say ''
    rows = tickets.pluck(:group_id, :ops_state, :id, :created_at)
    say "Tickets owned by the old owner (#{rows.size}), by group and ops_state:"
    routed = routed_group_ids(all_triggers)
    rows.group_by(&:first).sort_by { |group_id, _rows| group_name(group_id) }.each do |group_id, group_rows|
      note = routed.include?(group_id) ? ' (still routed to the old owner)' : ''
      say "  #{group_name(group_id)}: #{group_rows.size}#{note}"
      group_rows.group_by { |_g, state, _id, _created_at| state.presence || '(empty)' }.sort.each do |state, state_rows|
        say "    #{state}: #{state_rows.size} | ticket ids #{ticket_ids(state_rows.map { |row| row.last(2) })}"
      end
    end

    { triggers: all_triggers, tickets: rows }
  end

  def reassign_triggers!(to:, groups: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = triggers(groups:)
    warn_about_groups(groups, selected.map { |trigger| trigger_group_id(trigger) }, 'triggers')

    say "#{dry_run ? '[DRY RUN] ' : ''}Triggers of #{describe(old_owner)} -> #{describe(new_owner)}: #{selected.size}"
    selected.each do |trigger|
      new_name = renamed(trigger.name, new_owner)
      say "  ##{trigger.id} #{trigger.name}"
      say "    -> #{new_name}" if new_name != trigger.name
      say "    !! the name does not end with #{agent_name(old_owner).inspect}, it stays as it is" if new_name == trigger.name
      grant_group_access(new_owner, trigger_group_id(trigger), dry_run:)
      next if dry_run

      trigger.update!(name: new_name, perform: perform_with_owner(trigger.perform, new_owner), updated_by_id: 1)
    end
    say 'Nothing changed, run again with dry_run: false to apply.' if dry_run && selected.any?
    selected
  end

  def reassign_tickets!(to:, groups: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = tickets(groups:).to_a
    warn_about_groups(groups, selected.map(&:group_id), 'tickets')
    still_routed = routed_group_ids(triggers(groups:))
    if still_routed.any?
      raise ArgumentError, "Active triggers still route groups #{still_routed.map { |id| group_name(id) }.inspect} " \
                           "to #{describe(old_owner)}, run reassign_triggers! for them first"
    end

    say "#{dry_run ? '[DRY RUN] ' : ''}Tickets of #{describe(old_owner)} -> #{describe(new_owner)}: #{selected.size}"
    selected.group_by(&:group_id).each do |group_id, group_tickets|
      say "  group #{group_name(group_id)}: #{group_tickets.size} | ticket ids #{ticket_ids(group_tickets.map { |t| [t.id, t.created_at] })}"
      grant_group_access(new_owner, group_id, dry_run:)
    end
    if dry_run
      say 'Nothing changed, run again with dry_run: false to apply.' if selected.any?
      return selected
    end

    # without Transaction.execute the changes stay in the EventBuffer and a later Transaction.execute in the same
    # console session would dispatch them, notifying the new owner after all
    Transaction.execute(disable_notification: true, disable: %w[Transaction::Notification Transaction::Trigger]) do
      selected.each { |ticket| ticket.update!(owner_id: new_owner.id) }
    end
    say "Moved #{selected.size} tickets, #{tickets.count} left with #{describe(old_owner)}."
    selected
  end

  private

  def ticket_ids(rows)
    self.class.ticket_ids(rows, all: @all_ids)
  end

  def find_agent!(email)
    user = User.find_by(email: email.to_s.strip.downcase)
    raise ArgumentError, "No user with email #{email.inspect}" unless user
    raise ArgumentError, "#{describe(user)} is not an agent" unless user.permissions?('ticket.agent')

    user
  end

  def owner_id_set_by(trigger)
    trigger.perform&.dig('ticket.owner_id', 'value')&.to_i
  end

  def trigger_group_id(trigger)
    trigger.perform&.dig('ticket.group_id', 'value')&.to_i
  end

  def routed_group_ids(triggers)
    triggers.select(&:active).map { |trigger| trigger_group_id(trigger) }.uniq
  end

  # groups by the names the report shows ("Bratislava / Devín"; "Bratislava::Devín", as Zammad stores it, works too),
  # raises for any name that is not a group
  def find_groups!(names)
    stored = names.to_h { |name| [name, name.to_s.strip.split(GROUP_SEPARATOR.strip).map(&:strip).join('::')] }
    groups = Group.where(name: stored.values.uniq).index_by(&:name)
    unknown = stored.reject { |_name, value| groups.key?(value) }.keys
    if unknown.any?
      messages = unknown.map do |name|
        suggestions = suggest_groups(name)
        "#{name.inspect}#{suggestions.any? ? " (did you mean #{suggestions.map(&:inspect).join(' or ')}?)" : ''}"
      end
      raise ArgumentError, "Not a group in Triage: #{messages.join(', ')}"
    end

    stored.values.uniq.map { |value| groups[value] }
  end

  # ignores case and diacritics and matches the last part too, so "pezinok" finds "Pezinok" and "Devin" finds
  # "Bratislava / Devín"
  def suggest_groups(name)
    normalize = ->(value) { ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/\s+/, ' ').strip }
    wanted = normalize.call(name.to_s.gsub('::', GROUP_SEPARATOR))
    Group.all.map { |group| group_label(group) }.select do |label|
      normalize.call(label) == wanted || normalize.call(label.split(GROUP_SEPARATOR).last) == wanted
    end
  end

  # the admin UI saves ids as strings ("6") and shows value_completion, the portal saves integers without it; keep the
  # format the trigger has
  def perform_with_owner(perform, new_owner)
    owner = perform['ticket.owner_id'].dup
    owner['value'] = owner['value'].is_a?(String) ? new_owner.id.to_s : new_owner.id
    owner['value_completion'] = "#{agent_name(new_owner)} <#{new_owner.email}>" if owner.key?('value_completion')
    perform.merge('ticket.owner_id' => owner)
  end

  # municipalities in "ticket.address_municipality is ..." conditions, in any branch of the condition; only shown in
  # the report
  def trigger_municipalities(trigger)
    conditions_of(trigger.condition)
      .select { |name, spec| name == 'ticket.address_municipality' && spec['operator'] == 'is' }
      .flat_map { |_name, spec| Array(spec['value']) }
      .uniq
  end

  # [name, {operator, value, ...}] of every condition, in both formats Zammad stores:
  #   flat, as created by the portal:      { 'ticket.address_municipality' => { 'operator' => 'is', 'value' => [...] }, ... }
  #   nested, as saved by the admin UI in expert mode:
  #     { 'operator' => 'OR', 'conditions' => [{ 'operator' => 'AND', 'conditions' => [{ 'name' => ..., 'operator' => ..., 'value' => ... }] }] }
  def conditions_of(condition)
    return [] unless condition.is_a?(Hash)
    return Array(condition['conditions']).flat_map { |child| conditions_of(child) } if condition.key?('conditions')
    return [[condition['name'], condition]] if condition.key?('name')

    condition.map { |name, spec| [name, spec] }
  end

  def other_triggers_mentioning_old_owner(owner_triggers)
    old_id = old_owner.id.to_s
    (Trigger.all - owner_triggers).select do |trigger|
      conditions_of(trigger.condition).any? { |name, spec| name == 'ticket.owner_id' && Array(spec['value']).map(&:to_s).include?(old_id) }
    end
  end

  # a group with nothing of the old owner would otherwise just move nothing
  def warn_about_groups(groups, found_group_ids, what)
    return unless groups

    find_groups!(groups).each do |group|
      next if found_group_ids.include?(group.id)

      say "  !! #{describe(old_owner)} has no #{what} in group #{group_label(group).inspect}"
    end
  end

  def renamed(name, new_owner)
    old_suffix = " #{agent_name(old_owner)}"
    return name unless name.end_with?(old_suffix)

    "#{name.delete_suffix(old_suffix)} #{agent_name(new_owner)}"
  end

  def grant_group_access(user, group_id, dry_run:)
    group = Group.find_by(id: group_id)
    return if group.nil? || user.group_access?(group.id, 'full')

    say "    + #{describe(user)} gets full access to group #{group_label(group)}"
    return if dry_run

    user.group_names_access_map = user.group_names_access_map.merge(group.name => ['full'])
    user.save!
  end

  # the same as the portal names the agent in the 700 trigger name, see ResponsibleSubjects::TriageSetup#agent_name
  def agent_name(user)
    [user.firstname, user.lastname].compact_blank.join(' ')
  end

  def describe(user)
    "#{agent_name(user)} <#{user.email}> (##{user.id})"
  end

  # the group with its parents, "Bratislava / Devín"
  def group_label(group)
    group.name.split('::').join(GROUP_SEPARATOR)
  end

  def group_name(group_id)
    group = Group.find_by(id: group_id)
    group ? group_label(group) : group_id.inspect
  end

  def say(line)
    @out.puts(line)
  end
end
