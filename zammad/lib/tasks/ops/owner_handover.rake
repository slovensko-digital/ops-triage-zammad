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
# Ops::OwnerHandover::DEFAULT_TEST_CUSTOMER_LOGINS, the portal's anonymous user), are never moved, only counted.
namespace :ops do
  namespace :owner_handover do
    groups = -> { ENV['GROUPS'].presence&.split(';')&.map(&:strip) }
    dry_run = -> { ENV['APPLY'] != '1' }
    all_ids = -> { ENV['ALL_IDS'] == '1' }
    test_logins = -> { ENV['TEST_LOGINS'].presence&.split(';')&.map(&:strip) || Ops::OwnerHandover::DEFAULT_TEST_CUSTOMER_LOGINS }

    desc 'List the triggers routing tickets to an agent and the tickets they own'
    task :report, [:old_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call, test_customer_logins: test_logins.call).report
    end

    desc 'Point the triggers routing tickets to the old agent to the new one'
    task :triggers, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call, test_customer_logins: test_logins.call)
        .reassign_triggers!(to: args.fetch(:new_email), groups: groups.call, dry_run: dry_run.call)
    end

    desc 'List the groups with tickets not owned by the agent the group is routed to, with the commands fixing them'
    task conflicts: :environment do
      Ops::OwnerConflicts.new(all_ids: all_ids.call, test_customer_logins: test_logins.call).report
    end

    desc 'Move the tickets of the old agent to the new one, closed ones too, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call, test_customer_logins: test_logins.call)
        .reassign_tickets!(to: args.fetch(:new_email), groups: groups.call, dry_run: dry_run.call)
    end
  end
end
