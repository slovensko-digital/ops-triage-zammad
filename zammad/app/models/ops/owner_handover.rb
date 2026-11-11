# Hands over the work of an agent (volunteer) who stops working for us to other agents.
#
# New portal tickets get their owner from the 700 routing triggers ("700 - Priradenie podnetu skupine <municipality>
# <agent name>", created by the portal's responsible_subjects:activate_basic), one per municipality. The handover:
#
#   1. report             lists the triggers routing to the old owner and the tickets they own, by municipality,
#   2. reassign_triggers! points the triggers to the new owner, so no new tickets reach the old owner,
#   3. reassign_tickets!  moves the old owner's tickets to the new owner.
#
# A municipality's tickets cannot be moved while an active trigger still routes the municipality to the old owner.
# The new owner gets full access to the trigger's and the tickets' groups, the same access the portal gives the agent
# when it activates a municipality. Tickets move silently: no notifications to the new owner, no triggers.
#
# Both reassign methods only print the plan unless called with dry_run: false. Pass municipalities: to split the
# old owner's municipalities between several new owners, without it all of them go to the one new owner.
#
#   h = Ops::OwnerHandover.new('old@example.org')
#   h.report
#   h.reassign_triggers!(to: 'new@example.org', municipalities: ['Pezinok', 'Malacky'])
#   h.reassign_triggers!(to: 'new@example.org', municipalities: ['Pezinok', 'Malacky'], dry_run: false)
#   h.reassign_tickets!(to: 'new@example.org', municipalities: ['Pezinok', 'Malacky'], dry_run: false)
#
# The same from the shell: rake ops:owner_handover:{report,triggers,tickets}, see lib/tasks/ops/owner_handover.rake.
class Ops::OwnerHandover
  NO_MUNICIPALITY = '(bez oblasti)'.freeze

  attr_reader :old_owner

  def initialize(old_owner_email, out: $stdout)
    @old_owner = find_agent!(old_owner_email)
    @out = out
  end

  # triggers setting the old owner as the ticket owner, the 700 routing triggers and any other
  def triggers
    Trigger.order(:name).select { |trigger| owner_id_set_by(trigger) == old_owner.id }
  end

  def tickets(municipalities: nil)
    scope = Ticket.where(owner_id: old_owner.id)
    scope = scope.where(address_municipality: municipality_values(municipalities)) if municipalities
    scope.order(:id)
  end

  def report
    say "Old owner: #{describe(old_owner)}"
    say ''

    say "Triggers setting the old owner as the ticket owner (#{triggers.size}):"
    triggers.each do |trigger|
      say "  ##{trigger.id} #{trigger.active ? 'active' : 'INACTIVE'} | group #{group_name(trigger_group_id(trigger))} | " \
          "municipalities #{trigger_municipalities(trigger).inspect} | #{trigger.name}"
    end
    other = other_triggers_mentioning_old_owner
    if other.any?
      say ''
      say 'Other triggers mentioning the old owner, check them by hand:'
      other.each { |trigger| say "  ##{trigger.id} #{trigger.name}" }
    end

    say ''
    rows = tickets.pluck(:address_municipality, :ops_state, :id)
    say "Tickets owned by the old owner (#{rows.size}), by municipality and ops_state:"
    routed = triggers.select(&:active).flat_map { |trigger| trigger_municipalities(trigger) }
    rows.group_by { |municipality, _state, _id| municipality.presence || NO_MUNICIPALITY }.sort.each do |municipality, municipality_rows|
      note = routed.include?(municipality) ? ' (still routed to the old owner)' : ''
      say "  #{municipality}: #{municipality_rows.size}#{note}"
      municipality_rows.group_by { |_m, state, _id| state.presence || '(empty)' }.sort.each do |state, state_rows|
        say "    #{state}: #{state_rows.size} | ticket ids #{state_rows.map(&:last).join(', ')}"
      end
    end

    { triggers: triggers, tickets: rows }
  end

  def reassign_triggers!(to:, municipalities: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = triggers
    selected = selected.select { |trigger| trigger_municipalities(trigger).intersect?(municipalities) } if municipalities
    warn_about_municipalities(municipalities, selected.flat_map { |trigger| trigger_municipalities(trigger) }, 'triggers')
    warn_about_mixed_triggers(selected, municipalities)

    say "#{dry_run ? '[DRY RUN] ' : ''}Triggers of #{describe(old_owner)} -> #{describe(new_owner)}: #{selected.size}"
    selected.each do |trigger|
      new_name = renamed(trigger.name, new_owner)
      say "  ##{trigger.id} #{trigger.name}"
      say "    -> #{new_name}" if new_name != trigger.name
      say "    !! the name does not end with #{agent_name(old_owner).inspect}, it stays as it is" if new_name == trigger.name
      grant_group_access(new_owner, trigger_group_id(trigger), dry_run:)
      next if dry_run

      perform = trigger.perform.deep_dup
      perform['ticket.owner_id'] = perform['ticket.owner_id'].merge('value' => new_owner.id)
      trigger.update!(name: new_name, perform: perform, updated_by_id: 1)
    end
    say 'Nothing changed, run again with dry_run: false to apply.' if dry_run && selected.any?
    selected
  end

  def reassign_tickets!(to:, municipalities: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = tickets(municipalities:).to_a
    warn_about_municipalities(municipalities, selected.map { |ticket| ticket.address_municipality.presence || NO_MUNICIPALITY }, 'tickets')
    still_routed = still_routed_municipalities(municipalities)
    if still_routed.any?
      raise ArgumentError, "Active triggers still route #{still_routed.inspect} to #{describe(old_owner)}, " \
                           'run reassign_triggers! for them first'
    end

    say "#{dry_run ? '[DRY RUN] ' : ''}Tickets of #{describe(old_owner)} -> #{describe(new_owner)}: #{selected.size}"
    selected.group_by(&:group_id).each do |group_id, group_tickets|
      say "  group #{group_name(group_id)}: #{group_tickets.size} | ticket ids #{group_tickets.map(&:id).join(', ')}"
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

  def trigger_municipalities(trigger)
    Array(trigger.condition&.dig('ticket.address_municipality', 'value'))
  end

  def other_triggers_mentioning_old_owner
    pattern = /"ticket\.owner_id"=>\{[^}]*"value"=>\[?"?#{old_owner.id}\b/
    (Trigger.all - triggers).select { |trigger| trigger.condition.inspect.match?(pattern) || trigger.perform.inspect.match?(pattern) }
  end

  # catches typos: an unknown municipality, or one with nothing of the old owner, would otherwise just move nothing
  def warn_about_municipalities(municipalities, found, what)
    return unless municipalities

    municipalities.each do |municipality|
      if !known_municipalities.include?(municipality)
        suggestion = suggest_municipality(municipality)
        say "  !! #{municipality.inspect} is not a municipality in Triage#{suggestion ? ", did you mean #{suggestion.inspect}?" : ''}"
      elsif !found.include?(municipality)
        say "  !! #{describe(old_owner)} has no #{what} for #{municipality.inspect}"
      end
    end
  end

  # the address_municipality options: municipalities and, for cities, "City::District"
  def known_municipalities
    @known_municipalities ||= begin
      options = ObjectManager::Attribute.get(object: 'Ticket', name: 'address_municipality').data_option['options']
      flatten = ->(nodes) { Array(nodes).flat_map { |node| [node['value'] || node[:value], *flatten.call(node['children'] || node[:children])] } }
      [NO_MUNICIPALITY, *flatten.call(options)].to_set
    end
  end

  # ignores case and diacritics, so "pezinok" or "Banska Bystrica" are found
  def suggest_municipality(municipality)
    normalize = ->(name) { ActiveSupport::Inflector.transliterate(name.to_s).downcase.strip }
    known_municipalities.find { |known| normalize.call(known) == normalize.call(municipality) }
  end

  # a trigger for several municipalities moves as a whole
  def warn_about_mixed_triggers(selected, municipalities)
    return unless municipalities

    selected.each do |trigger|
      extra = trigger_municipalities(trigger) - municipalities
      say "  !! ##{trigger.id} also routes #{extra.inspect}, they move too" if extra.any?
    end
  end

  def still_routed_municipalities(municipalities)
    routed = triggers.select(&:active).flat_map { |trigger| trigger_municipalities(trigger) }.uniq
    municipalities ? routed & municipalities : routed
  end

  def municipality_values(municipalities)
    municipalities.flat_map { |municipality| municipality == NO_MUNICIPALITY ? [nil, ''] : [municipality] }
  end

  def renamed(name, new_owner)
    old_suffix = " #{agent_name(old_owner)}"
    return name unless name.end_with?(old_suffix)

    "#{name.delete_suffix(old_suffix)} #{agent_name(new_owner)}"
  end

  def grant_group_access(user, group_id, dry_run:)
    group = Group.find_by(id: group_id)
    return if group.nil? || user.group_access?(group.id, 'full')

    say "    + #{describe(user)} gets full access to group #{group.name}"
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

  def group_name(group_id)
    Group.find_by(id: group_id)&.name || group_id.inspect
  end

  def say(line)
    @out.puts(line)
  end
end
