# Groups the 700 routing triggers ("700 - Priradenie podnetu skupine <municipality> <agent name>") by shape, so the
# ones that differ from the known shapes stand out before a script changes them in bulk. Read only.
#
#   Ops::RoutingTriggerShapes.new.report
#   rake ops:routing_triggers:shapes
#
# A shape is the trigger's settings, condition and perform with the per-municipality values (municipality, group,
# owner and responsible subject ids) replaced by their type, e.g. Integer or String. Values that are the same in every
# 700 trigger (ticket.action, origin, process_type) are kept. Known shapes:
#
#   create             created by the portal (ResponsibleSubjects::TriageSetup): a flat condition,
#                      "ticket.action is create" and integer ids
#   create_or_changed  saved from the admin UI (expert mode): OR of the create branch and
#                      "responsible_subject has changed AND is <municipality>", string ids and value_completion
#
# Anything else is UNKNOWN. A trigger whose name or note does not match its municipality and owner, or whose owner
# does not exist, gets its own group with the failed checks.
class Ops::RoutingTriggerShapes
  PREFIX = '700 - Priradenie podnetu skupine '.freeze
  CONSTANT_FIELDS = %w[ticket.action ticket.origin ticket.process_type].freeze
  CREATE_FIELDS = %w[ticket.action ticket.address_municipality ticket.origin ticket.process_type].freeze
  CHANGED_FIELDS = %w[ticket.responsible_subject ticket.responsible_subject].freeze

  def initialize(out: $stdout)
    @out = out
  end

  # the 700 triggers by name, plus any trigger routing by municipality to an owner, in case it was renamed
  def triggers
    Trigger.order(:name).select do |trigger|
      trigger.name.start_with?('700') ||
        (trigger.perform&.key?('ticket.owner_id') && trigger.condition.to_json.include?('ticket.address_municipality'))
    end
  end

  def shapes
    triggers.group_by { |trigger| shape_of(trigger) }.sort_by { |_shape, shape_triggers| -shape_triggers.size }
  end

  def report
    grouped = shapes
    say "700 triggers: #{grouped.sum { |_shape, shape_triggers| shape_triggers.size }}, shapes: #{grouped.size}"
    grouped.each_with_index do |(shape, shape_triggers), index|
      failed = shape['checks'].reject { |_check, passed| passed }.keys
      say ''
      say "=== Shape #{index + 1}: #{label(shape)}#{failed.any? ? " (failed checks: #{failed.join(', ')})" : ''} - " \
          "#{shape_triggers.size} triggers"
      say JSON.pretty_generate(shape.except('checks'))
      shape_triggers.each { |trigger| say "  ##{trigger.id} #{trigger.active ? '' : '[INACTIVE] '}#{trigger.name}" }
    end
    grouped
  end

  def label(shape)
    kind, children = shape['condition']
    if kind == 'FLAT' && children.map(&:first) == CREATE_FIELDS
      'create'
    elsif kind == 'OR' && children.size == 2 &&
          children.map { |_and, branch| branch.map(&:first) }.sort == [CREATE_FIELDS, CHANGED_FIELDS]
      'create_or_changed'
    else
      'UNKNOWN'
    end
  end

  private

  def shape_of(trigger)
    condition = tree(trigger.condition)
    municipalities = municipalities_in(condition)
    owner = User.find_by(id: trigger.perform&.dig('ticket.owner_id', 'value'))

    {
      'attributes' => trigger.attributes.slice('activator', 'execution_condition_mode', 'disable_notification'),
      'condition' => shape_of_tree(condition),
      'perform' => (trigger.perform || {}).keys.sort.to_h { |key| [key, shape_of_spec(key, trigger.perform[key])] },
      'checks' => {
        'one municipality' => municipalities.size == 1,
        'owner exists' => !owner.nil?,
        'name is prefix + municipality + owner' => owner.present? && municipalities.size == 1 &&
          trigger.name == "#{PREFIX}#{municipalities.first} #{agent_name(owner)}",
        'note is prefix + municipality' => municipalities.size == 1 && trigger.note == "#{PREFIX}#{municipalities.first}",
      },
    }
  end

  # the condition in both formats Zammad stores, as [operator, children] for OR/AND, [name, spec] for a condition
  # and ['FLAT', [[name, spec], ...]] for the flat format the portal creates
  def tree(condition)
    return ['FLAT', []] unless condition.is_a?(Hash)
    return [condition['operator'], Array(condition['conditions']).map { |child| tree(child) }] if condition.key?('conditions')
    return [condition['name'], condition.except('name')] if condition.key?('name')

    ['FLAT', condition.map { |name, spec| [name, spec] }]
  end

  def leaves(node)
    kind, rest = node
    return rest if kind == 'FLAT'
    return rest.flat_map { |child| leaves(child) } if rest.is_a?(Array)

    [node]
  end

  def municipalities_in(condition)
    leaves(condition)
      .select { |name, spec| name == 'ticket.address_municipality' && spec['operator'] == 'is' }
      .flat_map { |_name, spec| Array(spec['value']) }
      .uniq
  end

  def shape_of_tree(node)
    kind, rest = node
    if kind == 'FLAT'
      ['FLAT', rest.map { |name, spec| [name, shape_of_spec(name, spec)] }.sort_by { |name, spec| [name, spec.to_json] }]
    elsif rest.is_a?(Array)
      [kind, rest.map { |child| shape_of_tree(child) }.sort_by(&:to_json)]
    else
      [kind, shape_of_spec(kind, rest)]
    end
  end

  def shape_of_spec(name, spec)
    return type_of(spec) unless spec.is_a?(Hash)

    spec.keys.sort.to_h do |key|
      kept = %w[operator pre_condition].include?(key) || (key == 'value' && CONSTANT_FIELDS.include?(name))
      [key, kept ? spec[key] : type_of(spec[key])]
    end
  end

  def type_of(value)
    case value
    when Array then "Array<#{value.map { |item| type_of(item) }.uniq.sort.join('|')}>"
    when Hash then "{#{value.keys.sort.map { |key| "#{key}:#{type_of(value[key])}" }.join(',')}}"
    when nil then 'nil'
    else value.class.name
    end
  end

  # the same as the portal names the agent in the 700 trigger name, see ResponsibleSubjects::TriageSetup#agent_name
  def agent_name(user)
    [user.firstname, user.lastname].compact_blank.join(' ')
  end

  def say(line)
    @out.puts(line)
  end
end
