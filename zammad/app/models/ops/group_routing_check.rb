# Checks that handing over by group (Ops::OwnerHandover) moves the right tickets: the tickets of each group should have
# the municipality and the responsible subject of the active 700 trigger routing to that group. Read only.
#
#   Ops::GroupRoutingCheck.new.report
#   rake ops:owner_handover:routing_check
#
# A ticket follows its group's trigger when its municipality is one the trigger's condition lists and its responsible
# subject is the one the trigger sets. A trigger saved from the admin UI (create_or_changed, see
# Ops::RoutingTriggerShapes) also routes a ticket whose responsible subject changed to the trigger's subject, so there
# the subject alone is enough. A group with several active triggers is followed when any of them matches.
#
# Only tickets of the process types the 700 triggers route are checked (resolution tickets are routed elsewhere);
# test tickets are left out. The report starts with the numbers, then lists the ticket ids not following the trigger,
# by group and by the municipality and responsible subject they have.
class Ops::GroupRoutingCheck
  include Ops::OwnerHandoverSupport

  # responsible_subject: [id string, label] the trigger sets; changed_subjects: ids of the "has changed" branch
  Route = Struct.new(:trigger, :municipalities, :process_types, :responsible_subject, :changed_subjects, keyword_init: true)

  RESULTS = {
    match: 'follow the trigger',
    changed_branch: 'follow the trigger by responsible subject change (municipality differs)',
    municipality: 'municipality differs',
    responsible_subject: 'responsible subject differs',
    both: 'municipality and responsible subject differ',
    no_trigger: 'group without an active 700 trigger',
  }.freeze
  FOLLOWING = %i[match changed_branch].freeze

  def initialize(out: $stdout, all_ids: false, test_customer_logins: DEFAULT_TEST_CUSTOMER_LOGINS)
    setup_handover_support(out:, all_ids:, test_customer_logins:)
  end

  # group id => [Route] of the active triggers setting a group from the municipality
  def routes_by_group
    @routes_by_group ||= Trigger.where(active: true).order(:id).each_with_object({}) do |trigger, routes|
      group_id = trigger_group_id(trigger)
      municipalities = trigger_municipalities(trigger)
      next unless group_id && municipalities.any?

      (routes[group_id] ||= []) << Route.new(
        trigger:, municipalities:,
        process_types: condition_values(trigger, 'ticket.process_type', 'is').map(&:to_s),
        responsible_subject: subject_key(trigger.perform&.dig('ticket.responsible_subject', 'value')),
        changed_subjects: condition_values(trigger, 'ticket.responsible_subject', 'is').filter_map { |subject| subject_key(subject)&.first }
      )
    end
  end

  # [result, group id, municipality, [subject id, label], id, created_at] of the checked tickets
  def results
    tickets_in_scope.pluck(:group_id, :address_municipality, :responsible_subject, :id, :created_at)
      .map do |group_id, municipality, subject, id, created_at|
        subject = subject_key(subject)
        [result(routes_by_group[group_id], municipality, subject), group_id, municipality, subject, id, created_at]
      end
  end

  def report
    rows = results
    say_routes
    say ''
    say_test_tickets_note(only_test_tickets(routed_tickets).count)
    out_of_scope = without_test_tickets(Ticket.where.not(id: routed_tickets.select(:id))).group(:process_type).count
    say "Tickets of process types the 700 triggers do not route, not checked: #{out_of_scope.sum { |_type, count| count }} " \
        "#{out_of_scope.transform_keys { |type| type.presence || '(empty)' }.inspect}"
    say ''
    say "Tickets checked: #{rows.size}"
    counts = rows.group_by(&:first).transform_values(&:size)
    RESULTS.each { |key, text| say "  #{text}: #{counts.fetch(key, 0)}" }

    not_following = rows.reject { |row| FOLLOWING.include?(row.first) }
    say ''
    say "Tickets not following their group's trigger (#{not_following.size}), by group:"
    by_group(not_following.map { |row| row.drop(1) }).each do |group_id, group_rows|
      say ''
      say "  #{group_name(group_id)}: #{group_rows.size} | #{describe_routes(routes_by_group[group_id])}"
      group_rows.group_by { |_group_id, municipality, subject| [municipality, subject] }
        .sort_by { |_key, key_rows| -key_rows.size }
        .each do |(municipality, subject), key_rows|
          say "    municipality #{(municipality.presence || '(empty)').inspect}, responsible subject #{describe_subject(subject)}: " \
              "#{key_rows.size} | ticket ids #{ticket_ids(key_rows)}"
        end
    end
    rows
  end

  private

  def result(routes, municipality, subject)
    return :no_trigger if routes.blank?

    subject_id = subject&.first
    return :match if routes.any? { |route| route.municipalities.include?(municipality) && route.responsible_subject&.first == subject_id }
    return :changed_branch if subject_id && routes.any? { |route| route.changed_subjects.include?(subject_id) }

    municipality_ok = routes.any? { |route| route.municipalities.include?(municipality) }
    subject_ok = routes.any? { |route| route.responsible_subject&.first == subject_id }
    if municipality_ok then :responsible_subject
    elsif subject_ok then :municipality
    else :both
    end
  end

  # the decision to hand over by group: groups routed by several triggers and municipalities routed to several groups
  def say_routes
    routes = routes_by_group
    say "Active 700 triggers: #{routes.sum { |_group_id, group_routes| group_routes.size }}, routing to #{routes.size} groups"
    several = routes.select { |_group_id, group_routes| group_routes.size > 1 }
    say "  groups routed by several triggers: #{several.size}"
    several.sort_by { |group_id, _routes| group_name(group_id) }.each do |group_id, group_routes|
      say "    #{group_name(group_id)} | #{describe_routes(group_routes)}"
    end
    many = routes.select { |_group_id, group_routes| group_routes.flat_map { |route| base_municipalities(route) }.uniq.size > 1 }
    say "  groups covering several municipalities: #{many.size}"
    many.sort_by { |group_id, _routes| group_name(group_id) }.each do |group_id, group_routes|
      say "    #{group_name(group_id)} | #{group_routes.flat_map { |route| base_municipalities(route) }.uniq.inspect}"
    end
    groups_by_municipality = routes.flat_map { |group_id, group_routes| group_routes.flat_map { |route| route.municipalities.map { |value| [value, group_id] } } }
                                   .group_by(&:first).transform_values { |pairs| pairs.map(&:last).uniq }
    split = groups_by_municipality.select { |_municipality, group_ids| group_ids.size > 1 }
    say "  municipalities routed to several groups: #{split.size}"
    split.sort.each { |municipality, group_ids| say "    #{municipality.inspect} -> #{group_ids.map { |id| group_name(id) }.join(', ')}" }
  end

  def describe_routes(routes)
    return '!! no active 700 trigger' if routes.blank?

    routes.map do |route|
      changed = route.changed_subjects.any? ? ', or responsible subject changed to it' : ''
      "trigger ##{route.trigger.id}: municipalities #{route.municipalities.inspect} -> responsible subject " \
        "#{describe_subject(route.responsible_subject)}#{changed}"
    end.join('; ')
  end

  def describe_subject(subject)
    subject ? "#{subject.last.inspect} (##{subject.first})" : '(empty)'
  end

  # "Bratislava" for "Bratislava" and "Bratislava::Devín"
  def base_municipalities(route)
    route.municipalities.map { |value| value.to_s.split('::').first }.uniq
  end

  # tickets of the process types the 700 triggers route, test tickets included
  def routed_tickets
    process_types = routes_by_group.values.flatten.flat_map(&:process_types).uniq
    process_types.any? ? Ticket.where(process_type: process_types) : Ticket.all
  end

  def tickets_in_scope
    without_test_tickets(routed_tickets).where.not(group_id: nil)
  end

  def condition_values(trigger, field, operator)
    conditions_of(trigger.condition)
      .select { |name, spec| name == field && spec['operator'] == operator }
      .flat_map { |_name, spec| Array(spec['value']) }
      .uniq
  end

  # [id string, label] of a responsible subject stored as { 'value' => id, 'label' => name }; the admin UI stores the
  # id as a string, the portal as an integer
  def subject_key(subject)
    return unless subject.is_a?(Hash) && subject['value'].present?

    [subject['value'].to_s, subject['label']]
  end
end
