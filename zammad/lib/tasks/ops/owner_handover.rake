# See Ops::OwnerHandover, Ops::OwnerConflicts and Ops::GroupRoutingCheck.
#
# Every task takes ALL_IDS=1 to list every ticket id, not only the 10 newest, and TEST_LOGINS='ops-user-63745;...' to set
# the test customers, whose tickets are left out and never moved.
#
# Through kamal wrap the whole command in double quotes, the alias runs it in a shell on the server, which would split
# GROUPS='Dubnica nad Váhom' into words otherwise:
#
#   kamal rake "'ops:owner_handover:tickets[old@example.org,new@example.org]' GROUPS='Dubnica nad Váhom'"
namespace :ops do
  namespace :owner_handover do
    list = ->(name) { ENV[name].presence&.split(';')&.map(&:strip) }
    options = lambda do
      { all_ids: ENV['ALL_IDS'] == '1',
        test_customer_logins: list.call('TEST_LOGINS') || Ops::OwnerHandoverSupport::DEFAULT_TEST_CUSTOMER_LOGINS }
    end
    reassign_options = ->(args) { { to: args.fetch(:new_email), groups: list.call('GROUPS'), dry_run: ENV['APPLY'] != '1' } }
    handover = ->(args) { Ops::OwnerHandover.new(args.fetch(:old_email), **options.call) }

    # rake 'ops:owner_handover:report[old@example.org]'
    desc 'List the triggers routing tickets to an agent and the tickets they own'
    task :report, [:old_email] => :environment do |_task, args|
      handover.call(args).report
    end

    # rake 'ops:owner_handover:triggers[old@example.org,new@example.org]' GROUPS='Pezinok;Bratislava / Devín' APPLY=1
    # GROUPS limits it to some groups, named as the report shows them; without APPLY=1 a dry run
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

    # rake 'ops:owner_handover:tickets[old@example.org,new@example.org]' GROUPS='Pezinok;Bratislava / Devín' APPLY=1
    # GROUPS limits it to some groups, named as the report shows them; without APPLY=1 a dry run
    desc 'Move the tickets of the old agent to the new one, closed ones too, silently'
    task :tickets, %i[old_email new_email] => :environment do |_task, args|
      handover.call(args).reassign_tickets!(**reassign_options.call(args))
    end
  end
end
