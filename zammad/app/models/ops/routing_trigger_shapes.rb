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
# Anything else is UNKNOWN. Only the settings decide the shape. Under its shape, each trigger is listed with its own
# problems: a name or note that does not match its municipality and owner (with the expected name), an owner that does
# not exist, not exactly one municipality, or a municipality Triage does not know (a typo in the condition).
#
# A ticket.action value that is not a string, e.g. ["create"] from a hand-written condition, is a problem too: Zammad
# compares the action with ==, so the trigger never fires (Selector::Sql). Saving the trigger in the admin UI fixes it.
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
      with_problems = shape_triggers.count { |trigger| problems(trigger).any? }
      say ''
      say "=== Shape #{index + 1}: #{label(shape)} - #{shape_triggers.size} triggers" \
          "#{with_problems.positive? ? ", #{with_problems} with problems" : ''}"
      say JSON.pretty_generate(shape)
      shape_triggers.each do |trigger|
        say "  ##{trigger.id} #{trigger.active ? '' : '[INACTIVE] '}#{trigger.name}"
        problems(trigger).each { |problem| say "    #{problem}" }
      end
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

  # what is wrong with one trigger beyond its shape, as lines for the report
  def problems(trigger)
    condition = tree(trigger.condition)
    municipalities = municipalities_in(condition)
    unknown = municipalities.reject { |municipality| known_municipalities.include?(municipality) }
    expected = expected_name(trigger)

    [
      ("municipalities: #{municipalities.inspect}, expected exactly one" if municipalities.size != 1),
      *unknown.map { |municipality| unknown_municipality(municipality) },
      ("owner #{trigger.perform&.dig('ticket.owner_id', 'value').inspect} does not exist" if owner_of(trigger).nil?),
      ("name differs, expected: #{expected}" if expected && trigger.name != expected),
      ("note differs, expected: #{PREFIX}#{municipalities.first}" if municipalities.size == 1 && trigger.note != "#{PREFIX}#{municipalities.first}"),
      ("ticket.action is not a string: #{action_values(condition).inspect}" unless action_values(condition).all?(String)),
    ].compact
  end

  private

  # an unknown municipality with the options it nearly matches: the same name under a parent ("Parent::Name"), or the
  # same text with other whitespace, case or unicode form, which looks the same in the UI and in inspect
  def unknown_municipality(municipality)
    similar = known_municipalities.select { |option| comparable(option.split('::').last) == comparable(municipality) }
    line = "unknown municipality: #{municipality.inspect} #{municipality.codepoints.inspect}"
    return "#{line}, no similar option" if similar.empty?

    "#{line}, similar options: #{similar.map { |option| "#{option.inspect} #{option.codepoints.inspect}" }.join(', ')}"
  end

  def comparable(text)
    text.to_s.unicode_normalize(:nfkc).gsub(/[[:space:]\u200B-\u200D\uFEFF]+/, ' ').strip.downcase
  end

  def shape_of(trigger)
    {
      'attributes' => trigger.attributes.slice('activator', 'execution_condition_mode', 'disable_notification'),
      'condition' => shape_of_tree(tree(trigger.condition)),
      'perform' => (trigger.perform || {}).keys.sort.to_h { |key| [key, shape_of_spec(key, trigger.perform[key])] },
    }
  end

  def owner_of(trigger)
    User.find_by(id: trigger.perform&.dig('ticket.owner_id', 'value'))
  end

  # nil when the name cannot be built: no owner, or not exactly one municipality
  def expected_name(trigger)
    owner = owner_of(trigger)
    municipalities = municipalities_in(tree(trigger.condition))
    return unless owner && municipalities.size == 1

    "#{PREFIX}#{municipalities.first} #{agent_name(owner)}"
  end

  # the address_municipality options: municipalities and, for cities, "City::District"
  def known_municipalities
    @known_municipalities ||= begin
      options = ObjectManager::Attribute.get(object: 'Ticket', name: 'address_municipality').data_option['options']
      flatten = ->(nodes) { Array(nodes).flat_map { |node| [node['value'] || node[:value], *flatten.call(node['children'] || node[:children])] } }
      flatten.call(options).to_set
    end
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

  def action_values(condition)
    leaves(condition).select { |name, _spec| name == 'ticket.action' }.map { |_name, spec| spec['value'] }
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
