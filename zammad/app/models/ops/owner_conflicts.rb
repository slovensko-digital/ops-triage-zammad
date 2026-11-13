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
# active triggers route to several owners, or an old or routed owner who is not an agent (the handover refuses them).
# Tickets without an owner and test tickets (the tickets of the customers with test_customer_logins:, by default
# Ops::OwnerHandoverSupport::DEFAULT_TEST_CUSTOMER_LOGINS) are left out, the report says how many test tickets it
# omitted. Ticket ids are listed newest first, only the first TICKET_IDS_SHOWN of them unless all_ids: true.
class Ops::OwnerConflicts
  include Ops::OwnerHandoverSupport

  NO_OWNER_ID = 1

  # tickets_by_owner: owner id => [[state id, ticket id, created_at]]
  Conflict = Struct.new(:group, :routed_owners, :tickets_by_owner, keyword_init: true) do
    def routed_owner
      routed_owners.keys.first if routed_owners.size == 1
    end

    def stray_owners
      tickets_by_owner.keys - [routed_owner]
    end
  end

  def initialize(out: $stdout, all_ids: false, test_customer_logins: DEFAULT_TEST_CUSTOMER_LOGINS)
    setup_handover_support(out:, all_ids:, test_customer_logins:)
  end

  def conflicts
    rows = without_test_tickets(owned_tickets).pluck(:group_id, :owner_id, :state_id, :id, :created_at)
    routes = routed_owners_by_group

    by_group(rows).filter_map do |group_id, group_rows|
      by_owner = group_rows.group_by { |row| row[1] }.transform_values { |owner_rows| owner_rows.map { |row| row.drop(2) } }
      routed = routes.fetch(group_id, {})
      next if routed.size == 1 && by_owner.keys == routed.keys
      next if routed.empty? && by_owner.size == 1

      Conflict.new(group: Group.find(group_id), routed_owners: routed, tickets_by_owner: by_owner)
    end
  end

  def report
    found = conflicts
    commands = Hash.new { |hash, key| hash[key] = [] }

    say_test_tickets_note(only_test_tickets(owned_tickets).count)
    say "Groups with tickets not owned by the routed owner (#{found.size}):"
    found.each do |conflict|
      label = group_label(conflict.group)
      say ''
      say "  #{label} | #{describe_routing(conflict.routed_owners)}"
      conflict.tickets_by_owner.sort_by { |owner_id, tickets| [owner_id == conflict.routed_owner ? 0 : 1, -tickets.size] }
        .each do |owner_id, tickets|
        if owner_id == conflict.routed_owner
          say "    #{describe_user_id(owner_id)}: #{count(tickets)} (routed owner)"
          next
        end

        say "    #{describe_user_id(owner_id)}: #{count(tickets)} | ticket ids #{ticket_ids(tickets)}"
        next unless conflict.routed_owner

        add_tickets_command(commands, user(owner_id), user(conflict.routed_owner), label, indent: '      ')
      end
    end

    say_tickets_commands('Commands', commands)
    found
  end

  private

  # tickets with an owner and a group, the test tickets too
  def owned_tickets
    Ticket.where.not(owner_id: NO_OWNER_ID).where.not(group_id: nil)
  end

  # tickets: [[state id, ticket id, created_at]]
  def count(tickets)
    "#{tickets.size} (#{tickets.count { |state_id, _id, _created_at| open_state_ids.include?(state_id) }} open)"
  end

  def open_state_ids
    @open_state_ids ||= Ticket::State.by_category(:open).pluck(:id)
  end
end
