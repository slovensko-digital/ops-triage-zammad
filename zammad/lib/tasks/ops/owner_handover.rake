# Hands over the triggers and tickets of an agent who stops working for us, see Ops::OwnerHandover.
#
#   rake 'ops:owner_handover:report[old@example.org]'
#   rake 'ops:owner_handover:triggers[old@example.org,new@example.org]' MUNICIPALITIES='Pezinok;Malacky' APPLY=1
#   rake 'ops:owner_handover:tickets[old@example.org,new@example.org]' MUNICIPALITIES='Pezinok;Malacky' APPLY=1
#
# Without APPLY=1 the tasks only print what they would change. Without MUNICIPALITIES all of the old owner's
# municipalities go to the new owner.
namespace :ops do
  namespace :owner_handover do
    municipalities = -> { ENV['MUNICIPALITIES'].presence&.split(';')&.map(&:strip) }
    dry_run = -> { ENV['APPLY'] != '1' }

    desc 'List the triggers routing tickets to an agent and the tickets they own'
    task :report, [:old_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email)).report
    end

    desc 'Point the triggers routing tickets to the old agent to the new one'
    task :triggers, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email))
        .reassign_triggers!(to: args.fetch(:new_email), municipalities: municipalities.call, dry_run: dry_run.call)
    end

    desc 'Move the tickets of the old agent to the new one, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      Ops::OwnerHandover.new(args.fetch(:old_email))
        .reassign_tickets!(to: args.fetch(:new_email), municipalities: municipalities.call, dry_run: dry_run.call)
    end
  end
end
