# Finds the groups whose tickets are not all owned by the agent the group is routed to, and prints the
# ops:owner_handover:tickets commands that fix them. Read only.
#
# Before Ops::OwnerHandover, owners were changed by hand: the 700 trigger got a new owner and the tickets were moved
# one by one, or not at all. So a group can have tickets of the previous owners next to the tickets of the current
# one. The current owner is the one the group's active trigger routes new tickets to (any active trigger setting
# ticket.group_id and ticket.owner_id). A group is listed when some of its tickets are owned by anyone else, or, when
# no single owner is routed, when its tickets have more than one owner.
#
#   Ops::OwnerConflicts.new.report
#   rake ops:owner_handover:conflicts
#
# Every other owner gets a command moving their tickets in the group to the current owner, one command per old and
# new owner with all their groups in GROUPS. No command is printed (!!) for a group no active trigger routes, a group
# active triggers route to several owners, or an old owner who is not an agent anymore (the handover refuses them).
# Tickets without an owner are left out.
class Ops::OwnerConflicts
  GROUP_SEPARATOR = Ops::OwnerHandover::GROUP_SEPARATOR
  NO_OWNER_ID = 1

  Conflict = Struct.new(:group, :routed_owners, :tickets_by_owner, keyword_init: true) do
    def routed_owner
      routed_owners.keys.first if routed_owners.size == 1
    end

    def stray_owners
      tickets_by_owner.keys - [routed_owner]
    end
  end

  def initialize(out: $stdout)
    @out = out
  end

  def conflicts
    rows = Ticket.where.not(owner_id: NO_OWNER_ID).where.not(group_id: nil).pluck(:group_id, :owner_id, :id, :state_id)
    routes = routed_owners_by_group

    rows.group_by(&:first).filter_map do |group_id, group_rows|
      by_owner = group_rows.group_by { |row| row[1] }.transform_values { |owner_rows| owner_rows.map { |row| row.values_at(2, 3) } }
      routed = routes.fetch(group_id, {})
      next if routed.size == 1 && by_owner.keys == routed.keys
      next if routed.empty? && by_owner.size == 1

      Conflict.new(group: Group.find(group_id), routed_owners: routed, tickets_by_owner: by_owner)
    end.sort_by { |conflict| group_label(conflict.group) }
  end

  def report
    found = conflicts
    commands = Hash.new { |hash, key| hash[key] = [] }

    say "Groups with tickets not owned by the routed owner (#{found.size}):"
    found.each do |conflict|
      say ''
      say "  #{group_label(conflict.group)} | #{describe_routing(conflict)}"
      conflict.tickets_by_owner.sort_by { |owner_id, tickets| [owner_id == conflict.routed_owner ? 0 : 1, -tickets.size] }
        .each do |owner_id, tickets|
        owner = user(owner_id)
        if owner_id == conflict.routed_owner
          say "    #{describe(owner)}: #{count(tickets)} (routed owner)"
          next
        end

        say "    #{describe(owner)}: #{count(tickets)} | ticket ids #{tickets.map(&:first).sort.join(', ')}"
        if conflict.routed_owner.nil?
          next
        elsif !owner&.permissions?('ticket.agent')
          say '      !! not an agent anymore, the handover refuses them, move these tickets by hand'
        else
          commands[[owner, user(conflict.routed_owner)]] << group_label(conflict.group)
        end
      end
    end

    say ''
    say "Commands (#{commands.size}), add APPLY=1 to apply:"
    commands.each do |(old_owner, new_owner), group_labels|
      say "  rake 'ops:owner_handover:tickets[#{old_owner.email},#{new_owner.email}]' GROUPS='#{group_labels.join(';')}'"
    end

    found
  end

  private

  # group id => { owner id => [trigger ids] } of the active triggers setting both the group and the owner
  def routed_owners_by_group
    Trigger.where(active: true).order(:id).each_with_object({}) do |trigger, routes|
      group_id = trigger.perform&.dig('ticket.group_id', 'value').presence&.to_i
      owner_id = trigger.perform&.dig('ticket.owner_id', 'value').presence&.to_i
      next unless group_id && owner_id

      ((routes[group_id] ||= {})[owner_id] ||= []) << trigger.id
    end
  end

  def describe_routing(conflict)
    case conflict.routed_owners.size
    when 0
      '!! no active trigger routes this group, pick the new owner by hand'
    when 1
      owner_id, trigger_ids = conflict.routed_owners.first
      "routed to #{describe(user(owner_id))} by trigger #{trigger_ids.map { |id| "##{id}" }.join(', ')}"
    else
      routes = conflict.routed_owners.map { |owner_id, trigger_ids| "#{describe(user(owner_id))} by #{trigger_ids.map { |id| "##{id}" }.join(', ')}" }
      "!! active triggers route it to several owners, fix the triggers first: #{routes.join('; ')}"
    end
  end

  def count(tickets)
    "#{tickets.size} (#{tickets.count { |_id, state_id| open_state_ids.include?(state_id) }} open)"
  end

  def open_state_ids
    @open_state_ids ||= Ticket::State.by_category(:open).pluck(:id)
  end

  def user(id)
    @users ||= {}
    @users.fetch(id) { @users[id] = User.find_by(id:) }
  end

  def describe(user)
    return 'unknown user' unless user

    "#{[user.firstname, user.lastname].compact_blank.join(' ')} <#{user.email}> (##{user.id})"
  end

  def group_label(group)
    group.name.split('::').join(GROUP_SEPARATOR)
  end

  def say(line)
    @out.puts(line)
  end
end
