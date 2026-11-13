# Hands over the triggers and tickets of an agent who stops working for us, see Ops::OwnerHandover.
#
#   rake ops:owner_handover:conflicts   (groups with tickets of earlier owners, see Ops::OwnerConflicts)
#   rake 'ops:owner_handover:report[old@example.org]'
#   rake 'ops:owner_handover:triggers[old@example.org,new@example.org]' GROUPS='Pezinok;Malacky' APPLY=1
#   rake 'ops:owner_handover:tickets[old@example.org,new@example.org]' GROUPS='Pezinok;Bratislava / Devín' APPLY=1
#
# GROUPS names groups with their parents, as the report shows them ("Bratislava / Devín"); an unknown name fails.
# Without APPLY=1 the tasks only print what they would change. Without GROUPS all of the old owner's groups go to the
# new owner. Ticket ids are listed newest first, the first 10 of them unless ALL_IDS=1.
# The report and conflicts print the tickets commands moving each group to the owner its active trigger routes it to.
# Test tickets, the tickets of the customers in TEST_LOGINS='ops-user-63745;ops-user-1' (by default
# Ops::OwnerHandoverSupport::DEFAULT_TEST_CUSTOMER_LOGINS, the portal's anonymous user), are never moved, only counted.
namespace :ops do
  namespace :owner_handover do
    list = ->(name) { ENV[name].presence&.split(';')&.map(&:strip) }
    # ALL_IDS and TEST_LOGINS, the same for every task
    options = lambda do
      { all_ids: ENV['ALL_IDS'] == '1',
        test_customer_logins: list.call('TEST_LOGINS') || Ops::OwnerHandoverSupport::DEFAULT_TEST_CUSTOMER_LOGINS }
    end
    # GROUPS and APPLY of the reassign tasks
    reassign_options = ->(args) { { to: args.fetch(:new_email), groups: list.call('GROUPS'), dry_run: ENV['APPLY'] != '1' } }
    handover = ->(args) { Ops::OwnerHandover.new(args.fetch(:old_email), **options.call) }

    desc 'List the triggers routing tickets to an agent and the tickets they own'
    task :report, [:old_email] => :environment do |_task, args|
      handover.call(args).report
    end

    desc 'Point the triggers routing tickets to the old agent to the new one'
    task :triggers, %i[old_email new_email] => :environment do |_task, args|
      handover.call(args).reassign_triggers!(**reassign_options.call(args))
    end

    desc 'List the groups with tickets not owned by the agent the group is routed to, with the commands fixing them'
    task conflicts: :environment do
      Ops::OwnerConflicts.new(**options.call).report
    end

    desc 'Move the tickets of the old agent to the new one, closed ones too, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      handover.call(args).reassign_tickets!(**reassign_options.call(args))
    end
  end
end
