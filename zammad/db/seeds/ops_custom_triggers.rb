Trigger.find_or_initialize_by(name: 'ops - preposielanie nových podnetov PRO zodpovedným subjektom').tap do |trigger|
  trigger.condition = {
    "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
    "ticket.responsible_subject" => { "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
    "ticket.ops_state" => { "operator" => "is", "value" => "sent_to_responsible" },
  }
  trigger.perform = {
    "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový podnet pre zodpovedný subjekt").id }
  }
  trigger.activator = "action"
  trigger.execution_condition_mode = "selective"
  trigger.active = true
  trigger.updated_by_id = 1
  trigger.created_by_id = 1
end.save!

Trigger.find_or_initialize_by(name: 'ops - preposielanie upravených podnetov PRO zodpovedným subjektom').tap do |trigger|
  trigger.condition = {
    "operator" => "AND", "conditions" => [
      { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
      { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
      { "operator" => "OR", "conditions" => [
        { "name" => "ticket.title", "operator" => "has changed" },
        { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.issue_type", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.responsible_subject", "operator" => "has changed" },
        { "name" => "ticket.category", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.subcategory", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.subtype", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_municipality", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_municipality_district", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_street", "operator" => "has changed" },
        { "name" => "ticket.address_house_number", "operator" => "has changed" },
        { "name" => "ticket.address_postcode", "operator" => "has changed" },
        { "name" => "ticket.address_lat", "operator" => "has changed" },
        { "name" => "ticket.address_lon", "operator" => "has changed" },
        { "name" => "ticket.likes_count", "operator" => "has changed" },
        { "name" => "ticket.portal_url", "operator" => "has changed" },
      ]}
    ]
  }
  trigger.perform = {
    "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre zodpovedný subjekt").id }
  }
  trigger.activator = "action"
  trigger.execution_condition_mode = "selective"
  trigger.active = true
  trigger.updated_by_id = 1
  trigger.created_by_id = 1
end.save!

Trigger.find_or_initialize_by(name: 'ops - preposielanie nových komentárov PRO zodpovedným subjektom').tap do |trigger|
  trigger.condition = {
    "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
    "ticket.responsible_subject" => { "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
    "ticket.ops_state" => { "operator" => "is", "value" => "sent_to_responsible" },
    "article.internal" => { "operator" => "is", "value" => false },
  }
  trigger.perform = {
    "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový komentár pre zodpovedný subjekt").id }
  }
  trigger.activator = "action"
  trigger.execution_condition_mode = "selective"
  trigger.active = true
  trigger.updated_by_id = 1
  trigger.created_by_id = 1
end.save!


Trigger.find_or_initialize_by(name: 'ops - preposielanie upravených podnetov na portál').tap do |trigger|
  trigger.condition = {
    "operator" => "AND", "conditions" => [
      { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
      { "operator" => "OR", "conditions" => [
        { "name" => "ticket.title", "operator" => "has changed" },
        { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.issue_type", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.responsible_subject", "operator" => "has changed" },
        { "name" => "ticket.category", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.subcategory", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.subtype", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_municipality", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_municipality_district", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.address_street", "operator" => "has changed" },
        { "name" => "ticket.address_house_number", "operator" => "has changed" },
        { "name" => "ticket.address_postcode", "operator" => "has changed" },
        { "name" => "ticket.address_lat", "operator" => "has changed" },
        { "name" => "ticket.address_lon", "operator" => "has changed" },
        { "name" => "ticket.investment", "operator" => "has changed", "value" => [] },
        { "name" => "ticket.likes_count", "operator" => "has changed" },
        { "name" => "ticket.portal_url", "operator" => "has changed" },
      ]}
    ]
  }
  trigger.perform = {
    "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre OPS portál").id }
  }
  trigger.activator = "action"
  trigger.execution_condition_mode = "selective"
  trigger.active = true
  trigger.updated_by_id = 1
  trigger.created_by_id = 1
end.save!

Trigger.find_or_initialize_by(name: 'ops - preposielanie nových komentárov na portál').tap do |trigger|
  trigger.condition = {
    "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
    "article.internal" => { "operator" => "is", "value" => false },
    "article.body" => { "operator" => "contains", "value" => "[[ops portal]]" },
    "article.action" => { "operator" => "is", "value" => "create" }
  }
  trigger.perform = {
    "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový komentár pre OPS portál").id }
  }
  trigger.activator = "action"
  trigger.execution_condition_mode = "selective"
  trigger.active = true
  trigger.updated_by_id = 1
  trigger.created_by_id = 1
end.save!
