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
namespace :ops do
  namespace :owner_handover do
    groups = -> { ENV['GROUPS'].presence&.split(';')&.map(&:strip) }
    dry_run = -> { ENV['APPLY'] != '1' }
    all_ids = -> { ENV['ALL_IDS'] == '1' }

    desc 'List the triggers routing tickets to an agent and the tickets they own'
    task :report, [:old_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call).report
    end

    desc 'Point the triggers routing tickets to the old agent to the new one'
    task :triggers, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call)
        .reassign_triggers!(to: args.fetch(:new_email), groups: groups.call, dry_run: dry_run.call)
    end

    desc 'List the groups with tickets not owned by the agent the group is routed to, with the commands fixing them'
    task conflicts: :environment do
      Ops::OwnerConflicts.new(all_ids: all_ids.call).report
    end

    desc 'Move the tickets of the old agent to the new one, closed ones too, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email), all_ids: all_ids.call)
        .reassign_tickets!(to: args.fetch(:new_email), groups: groups.call, dry_run: dry_run.call)
    end
  end
end
