# Hands over the triggers and tickets of an agent who stops volunteering, group by group: the 700 routing triggers
# set each new ticket's group and owner, a trigger moves as a whole and tickets move with their group.
#
#   1. report             the old owner's triggers and tickets by group, with commands moving them to the routed owner
#   2. reassign_triggers! points the triggers to the new owner, who gets full access to the groups
#   3. reassign_tickets!  moves the tickets, closed ones too (they can be reopened), without notifications or triggers;
#                         refused while an active trigger still routes the group to the old owner
#
# Test tickets (customers in test_customer_logins:) are never moved. The reassign methods are dry runs unless
# dry_run: false; groups: limits them to some groups, named as the report shows them ("Bratislava / Devín").
#
#   h = Ops::OwnerHandover.new('old@example.org')
#   h.report
#   h.reassign_triggers!(to: 'new@example.org', groups: ['Pezinok'], dry_run: false)
#   h.reassign_tickets!(to: 'new@example.org', groups: ['Pezinok'], dry_run: false)
class Ops::OwnerHandover
  include Ops::OwnerHandoverSupport

  attr_reader :old_owner

  def initialize(old_owner_email, out: $stdout, all_ids: false, test_customer_logins: DEFAULT_TEST_CUSTOMER_LOGINS)
    setup_handover_support(out:, all_ids:, test_customer_logins:)
    @old_owner = find_agent!(old_owner_email)
  end

  # every trigger setting the old owner, not only the 700 ones
  def triggers(groups: nil)
    selected = Trigger.order(:name).select { |trigger| trigger_owner_id(trigger) == old_owner.id }
    return selected unless groups

    ids = find_groups!(groups).map(&:id)
    selected.select { |trigger| ids.include?(trigger_group_id(trigger)) }
  end

  def tickets(groups: nil)
    without_test_tickets(owned_tickets(groups:)).order(:id)
  end

  def test_tickets(groups: nil)
    only_test_tickets(owned_tickets(groups:)).order(:id)
  end

  def report
    all_triggers = triggers
    test_rows = test_tickets.pluck(:group_id, :id, :created_at)
    say "Old owner: #{describe(old_owner)}"
    say ''
    say_test_tickets_note(test_rows.size)
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
    say "Tickets owned by the old owner (#{rows.size}, #{test_rows.size} test tickets omitted), by group and ops_state, with the owner the group is routed to now:"
    routes = routed_owners_by_group
    commands = Hash.new { |hash, key| hash[key] = [] }
    still_routed = []
    by_group(rows).each do |group_id, group_rows|
      label = group_name(group_id)
      routed = routes.fetch(group_id, {})
      say "  #{label}: #{group_rows.size} | #{describe_routing(routed, old_owner_id: old_owner.id)}"
      group_rows.group_by { |_group_id, state, _id, _created_at| state.presence || '(empty)' }.sort.each do |state, state_rows|
        say "    #{state}: #{state_rows.size} | ticket ids #{ticket_ids(state_rows)}"
      end

      routed_owner_id = single_routed_owner_id(routed)
      if routed_owner_id == old_owner.id
        still_routed << label
      elsif routed_owner_id
        add_tickets_command(commands, old_owner, user(routed_owner_id), label, indent: '    ')
      end
    end

    if test_rows.any?
      say ''
      say "Test tickets owned by the old owner, omitted, never moved (#{test_rows.size}):"
      by_group(test_rows).each do |group_id, group_rows|
        say "  #{group_name(group_id)}: #{group_rows.size} | ticket ids #{ticket_ids(group_rows)}"
      end
    end

    if still_routed.any?
      say ''
      say 'Groups still routed to the old owner, hand over their triggers first (pick NEW_EMAIL), then run the report again:'
      say "  rake 'ops:owner_handover:triggers[#{old_owner.email},NEW_EMAIL]' GROUPS='#{still_routed.join(';')}'"
    end

    say_tickets_commands('Commands moving the tickets to the routed owner', commands)

    { triggers: all_triggers, tickets: rows, test_tickets: test_rows }
  end

  def reassign_triggers!(to:, groups: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = triggers(groups:)
    warn_about_groups(groups, selected.map { |trigger| trigger_group_id(trigger) }, 'triggers')

    say_plan('Triggers', new_owner, selected.size, dry_run:)
    selected.each do |trigger|
      new_name = renamed(trigger.name, new_owner)
      say "  ##{trigger.id} #{trigger.name}"
      say "    -> #{new_name}" if new_name != trigger.name
      say "    !! the name does not end with #{agent_name(old_owner).inspect}, it stays as it is" if new_name == trigger.name
      grant_group_access(new_owner, trigger_group_id(trigger), dry_run:)
      next if dry_run

      trigger.update!(name: new_name, perform: perform_with_owner(trigger.perform, new_owner), updated_by_id: 1)
    end
    say_dry_run_hint if dry_run && selected.any?
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

    say_plan('Tickets', new_owner, selected.size, dry_run:)
    by_group(selected.map { |ticket| [ticket.group_id, ticket.id, ticket.created_at] }).each do |group_id, group_rows|
      say "  group #{group_name(group_id)}: #{group_rows.size} | ticket ids #{ticket_ids(group_rows)}"
      grant_group_access(new_owner, group_id, dry_run:)
    end
    test_rows = test_tickets(groups:).pluck(:id, :created_at)
    say ''
    say_test_tickets_note(test_rows.size)
    say "  staying with the old owner | ticket ids #{ticket_ids(test_rows)}" if test_rows.any?
    if dry_run
      say_dry_run_hint if selected.any?
      return selected
    end

    # without Transaction.execute the changes stay in the EventBuffer and a later Transaction.execute in the same
    # console session would dispatch them, notifying the new owner after all
    Transaction.execute(disable_notification: true, disable: %w[Transaction::Notification Transaction::Trigger]) do
      selected.each { |ticket| ticket.update!(owner_id: new_owner.id) }
    end
    say ''
    say "Moved #{selected.size} tickets, #{tickets.count} left with #{describe(old_owner)} " \
        "(and #{test_tickets.count} test tickets)."
    selected
  end

  private

  def say_plan(what, new_owner, count, dry_run:)
    say "#{dry_run ? '[DRY RUN] ' : ''}#{what} of #{describe(old_owner)} -> #{describe(new_owner)}: #{count}"
  end

  def say_dry_run_hint
    say ''
    say 'Nothing changed, run again with dry_run: false to apply.'
  end

  def owned_tickets(groups: nil)
    scope = Ticket.where(owner_id: old_owner.id)
    scope = scope.where(group_id: find_groups!(groups).map(&:id)) if groups
    scope
  end

  def find_agent!(email)
    user = User.find_by(email: email.to_s.strip.downcase)
    raise ArgumentError, "No user with email #{email.inspect}" unless user
    raise ArgumentError, "#{describe(user)} is not an agent" unless agent?(user)

    user
  end

  def routed_group_ids(triggers)
    triggers.select(&:active).map { |trigger| trigger_group_id(trigger) }.uniq
  end

  # "Bratislava / Devín" or "Bratislava::Devín"; raises ArgumentError for an unknown name
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

  # ignores case and diacritics and matches the last part: "Devin" finds "Bratislava / Devín"
  def suggest_groups(name)
    normalize = ->(value) { ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/\s+/, ' ').strip }
    wanted = normalize.call(name.to_s.gsub('::', GROUP_SEPARATOR))
    Group.all.map { |group| group_label(group) }.select do |label|
      normalize.call(label) == wanted || normalize.call(label.split(GROUP_SEPARATOR).last) == wanted
    end
  end

  # keep the trigger's format: the admin UI saves string ids with value_completion, the portal integers without it
  def perform_with_owner(perform, new_owner)
    owner = perform['ticket.owner_id'].dup
    owner['value'] = owner['value'].is_a?(String) ? new_owner.id.to_s : new_owner.id
    owner['value_completion'] = "#{agent_name(new_owner)} <#{new_owner.email}>" if owner.key?('value_completion')
    perform.merge('ticket.owner_id' => owner)
  end

  def trigger_municipalities(trigger)
    conditions_of(trigger.condition)
      .select { |name, spec| name == 'ticket.address_municipality' && spec['operator'] == 'is' }
      .flat_map { |_name, spec| Array(spec['value']) }
      .uniq
  end

  # [name, spec] of every condition, flat as the portal creates it ({ name => spec }) or nested as the admin UI saves it
  # in expert mode ({ 'operator' => 'OR', 'conditions' => [{ 'name' => name, ... }] })
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
end
