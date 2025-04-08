class OpsUpdateNotificationTriggersConditions < ActiveRecord::Migration[7.1]
  def up
    Trigger.find_by(name: 'ops - preposielanie nových podnetov PRO zodpovedným subjektom').update(
      condition: {
        "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
        "ticket.responsible_subject" => { "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
        "ticket.ops_state" => { "operator" => "is", "value" => "sent_to_responsible" },
      }
    )

    Trigger.find_by(name: 'ops - preposielanie upravených podnetov PRO zodpovedným subjektom').update(
      condition: {
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
    )

    Trigger.find_by(name: 'ops - preposielanie nových komentárov PRO zodpovedným subjektom').update(
      condition: {
        "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
        "ticket.responsible_subject" => { "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
        "ticket.ops_state" => { "operator" => "is", "value" => "sent_to_responsible" },
        "article.internal" => { "operator" => "is", "value" => false },
      }
    )

    Trigger.find_by(name: 'ops - preposielanie upravených podnetov na portál').update(
      condition: {
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
    )

    Trigger.find_by(name: 'ops - preposielanie nových komentárov na portál').update(
      condition: {
        "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
        "article.internal" => { "operator" => "is", "value" => false },
        "article.body" => { "operator" => "contains", "value" => "[[ops portal]]" },
        "article.action" => { "operator" => "is", "value" => "create" }
      }
    )
  end

  def down
    # no rollback needed
  end
end
