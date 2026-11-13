# Shared by Ops::OwnerHandover and Ops::OwnerConflicts; call setup_handover_support in the initializer.
module Ops::OwnerHandoverSupport
  GROUP_SEPARATOR = ' / '.freeze
  TICKET_IDS_SHOWN = 10
  # the portal creates the Triage customer of portal user <id> with login "ops-user-<id>" (ZammadApiClient#create_customer!);
  # portal user 63745 is the anonymous user all test tickets were created with
  DEFAULT_TEST_CUSTOMER_LOGINS = %w[ops-user-63745].freeze

  private

  def setup_handover_support(out:, all_ids:, test_customer_logins:)
    @out = out
    @all_ids = all_ids
    @test_customer_logins = Array(test_customer_logins).map { |login| login.to_s.strip.downcase }.compact_blank.uniq
    found = User.where(login: @test_customer_logins).pluck(:login, :id).to_h
    @test_customer_ids = found.values
    @unknown_test_logins = @test_customer_logins - found.keys
  end

  def trigger_owner_id(trigger)
    trigger.perform&.dig('ticket.owner_id', 'value').presence&.to_i
  end

  def trigger_group_id(trigger)
    trigger.perform&.dig('ticket.group_id', 'value').presence&.to_i
  end

  def trigger_municipalities(trigger)
    conditions_of(trigger.condition)
      .select { |name, spec| name == 'ticket.address_municipality' && spec['operator'] == 'is' }
      .flat_map { |_name, spec| Array(spec['value']) }
      .uniq
  end

  # [name, spec] of every condition, flat as the portal creates it ({ name => spec }) or nested as the admin UI saves it
  # in expert mode ({ 'operator' => 'OR', 'conditions' => [{ 'name' => name, ... }] })
  def conditions_of(condition)
    return [] unless condition.is_a?(Hash)
    return Array(condition['conditions']).flat_map { |child| conditions_of(child) } if condition.key?('conditions')
    return [[condition['name'], condition]] if condition.key?('name')

    condition.map { |name, spec| [name, spec] }
  end

  # group id => { owner id => [trigger ids] } of the active triggers setting both the group and the owner
  def routed_owners_by_group
    Trigger.where(active: true).order(:id).each_with_object({}) do |trigger, routes|
      group_id = trigger_group_id(trigger)
      owner_id = trigger_owner_id(trigger)
      next unless group_id && owner_id

      ((routes[group_id] ||= {})[owner_id] ||= []) << trigger.id
    end
  end

  def single_routed_owner_id(routed)
    routed.keys.first if routed.size == 1
  end

  def describe_routing(routed, old_owner_id: nil)
    by = ->(trigger_ids) { trigger_ids.map { |id| "##{id}" }.join(', ') }
    case routed.size
    when 0
      '!! no active trigger routes this group, pick the new owner by hand'
    when 1
      owner_id, trigger_ids = routed.first
      return "still routed to the old owner by trigger #{by.call(trigger_ids)}" if owner_id == old_owner_id

      "routed to #{describe_user_id(owner_id)} by trigger #{by.call(trigger_ids)}"
    else
      routes = routed.map { |owner_id, trigger_ids| "#{describe_user_id(owner_id)} by #{by.call(trigger_ids)}" }
      "!! active triggers route it to several owners, fix the triggers first: #{routes.join('; ')}"
    end
  end

  def without_test_tickets(scope)
    @test_customer_ids.any? ? scope.where.not(customer_id: @test_customer_ids) : scope
  end

  def only_test_tickets(scope)
    @test_customer_ids.any? ? scope.where(customer_id: @test_customer_ids) : scope.none
  end

  def say_test_tickets_note(count)
    say "Test tickets omitted: #{count} (customers #{@test_customer_logins.presence&.join(', ') || 'none'})"
    @unknown_test_logins.each { |login| say "  !! no user with login #{login.inspect}, nothing omitted for it" }
  end

  # commands: { [old owner, new owner] => [group labels] }; the tickets task refuses non-agents on either side
  def add_tickets_command(commands, old_owner, new_owner, group_label, indent:)
    if !agent?(new_owner)
      say "#{indent}!! the routed owner is not an agent, the handover refuses them, fix the trigger first"
    elsif !agent?(old_owner)
      say "#{indent}!! not an agent anymore, the handover refuses them, move these tickets by hand"
    else
      commands[[old_owner, new_owner]] << group_label
    end
  end

  def say_tickets_commands(title, commands)
    say ''
    say "#{title} (#{commands.size}), add APPLY=1 to apply:"
    commands.each { |(old_owner, new_owner), group_labels| say "  #{tickets_command(old_owner, new_owner, group_labels)}" }
  end

  # TEST_LOGINS when not the default, so the command omits the same test tickets
  def tickets_command(old_owner, new_owner, group_labels)
    command = "rake 'ops:owner_handover:tickets[#{old_owner.email},#{new_owner.email}]' GROUPS='#{group_labels.join(';')}'"
    return command if @test_customer_logins.sort == DEFAULT_TEST_CUSTOMER_LOGINS.sort

    "#{command} TEST_LOGINS='#{@test_customer_logins.join(';')}'"
  end

  # "12, 11, 10, ... (245 more)" of rows ending with [id, created_at], the newest first
  def ticket_ids(rows)
    ids = rows.map { |row| row.last(2) }.sort_by { |id, created_at| [created_at, id] }.reverse.map(&:first)
    return ids.join(', ') if @all_ids || ids.size <= TICKET_IDS_SHOWN

    "#{ids.first(TICKET_IDS_SHOWN).join(', ')}, ... (#{ids.size - TICKET_IDS_SHOWN} more)"
  end

  # rows starting with the group id, by group label
  def by_group(rows)
    rows.group_by(&:first).sort_by { |group_id, _rows| group_name(group_id) }
  end

  def agent?(user)
    user&.permissions?('ticket.agent')
  end

  def user(id)
    @users ||= {}
    @users.fetch(id) { @users[id] = User.find_by(id:) }
  end

  # the same as the portal names the agent in the 700 trigger name, see ResponsibleSubjects::TriageSetup#agent_name
  def agent_name(user)
    [user.firstname, user.lastname].compact_blank.join(' ')
  end

  def describe(user)
    "#{agent_name(user)} <#{user.email}> (##{user.id})"
  end

  def describe_user_id(id)
    user(id) ? describe(user(id)) : "unknown user ##{id}"
  end

  def group_label(group)
    group.name.split('::').join(GROUP_SEPARATOR)
  end

  def group_name(group_id)
    @groups ||= {}
    group = @groups.fetch(group_id) { @groups[group_id] = Group.find_by(id: group_id) }
    group ? group_label(group) : group_id.inspect
  end

  def say(line)
    @out.puts(line)
  end
end
