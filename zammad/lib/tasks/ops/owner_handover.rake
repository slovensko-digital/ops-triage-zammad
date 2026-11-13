# See Ops::OwnerHandover and Ops::OwnerConflicts.
#
#   rake ops:owner_handover:conflicts
#   rake 'ops:owner_handover:report[old@example.org]'
#   rake 'ops:owner_handover:triggers[old@example.org,new@example.org]' GROUPS='Pezinok;Bratislava / Devín' APPLY=1
#   rake 'ops:owner_handover:tickets[old@example.org,new@example.org]' GROUPS='Pezinok;Bratislava / Devín' APPLY=1
#
# Without APPLY=1 a dry run. ALL_IDS=1 lists every ticket id, not only the 10 newest. TEST_LOGINS='ops-user-63745;...'
# sets the test customers, whose tickets are never moved.
namespace :ops do
  namespace :owner_handover do
    list = ->(name) { ENV[name].presence&.split(';')&.map(&:strip) }
    options = lambda do
      { all_ids: ENV['ALL_IDS'] == '1',
        test_customer_logins: list.call('TEST_LOGINS') || Ops::OwnerHandoverSupport::DEFAULT_TEST_CUSTOMER_LOGINS }
    end
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
