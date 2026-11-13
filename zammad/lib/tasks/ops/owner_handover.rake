# See Ops::OwnerHandover, Ops::OwnerConflicts and Ops::GroupRoutingCheck.
#
# GROUPS='Pezinok;Bratislava / Devín' limits triggers and tickets to some groups. Without APPLY=1 a dry run.
# ALL_IDS=1 lists every ticket id, not only the 10 newest. TEST_LOGINS='ops-user-63745;...' sets the test customers,
# whose tickets are never moved.
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

    desc "Check that the tickets of each group have the municipality and responsible subject of the group's 700 trigger"
    task routing_check: :environment do
      Ops::GroupRoutingCheck.new(**options.call).report
    end

    desc 'Move the tickets of the old agent to the new one, closed ones too, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      handover.call(args).reassign_tickets!(**reassign_options.call(args))
    end
  end
end
