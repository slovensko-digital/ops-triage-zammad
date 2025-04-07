class OpsAddPortalWebhooksAndTriggers < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    # add article.created portal webhook
    Webhook.find_or_initialize_by(name: 'OPS - Nový komentár pre OPS portál').tap do |webhook|
      webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal')
      webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
      webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
      webhook.note = "Slúži na preposielanie nových komentárov ma portál Odkazu pre starostu"
      webhook.customized_payload = true
      webhook.custom_payload = {
        "type" => "article.created",
        "timestamp" => "\#{article.updated_at}",
        "data" => {
          "ticket_id" => "\#{ticket.id}",
          "article_id" => "\#{article.id}"
        }
      }.to_json
      webhook.preferences = {}
      webhook.active = true
      webhook.updated_by_id = 1
      webhook.created_by_id = 1
    end.save!

    # add ticket.updated portal webhook
    Webhook.find_or_initialize_by(name: 'OPS - Upravený podnet pre OPS portál').tap do |webhook|
      webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal')
      webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
      webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
      webhook.note = "Slúži na preposielanie úprav podnetov na portál Odkazu pre starostu"
      webhook.customized_payload = true
      webhook.custom_payload = {
        "type" => "ticket.updated",
        "timestamp" => "\#{ticket.updated_at}",
        "data" => {
          "ticket_id" => "\#{ticket.id}"
        }
      }.to_json
      webhook.preferences = {}
      webhook.active = true
      webhook.updated_by_id = 1
      webhook.created_by_id = 1
    end.save!


    Trigger.find_or_initialize_by(name: 'ops - preposielanie upravených podnetov na portál').tap do |trigger|
      trigger.condition = {
        "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
        "operator" => "OR", "conditions" => [
          { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
          { "name" => "ticket.responsible_subject", "operator" => "has changed" },
          { "name" => "ticket.category", "operator" => "has changed", "value" => [] },
          { "name" => "ticket.subcategory", "operator" => "has changed", "value" => [] },
          { "name" => "ticket.subtype", "operator" => "has changed", "value" => [] },
          { "name" => "ticket.address_municipality", "operator" => "has changed", "value" => [] },
          { "name" => "ticket.address_street", "operator" => "has changed" },
          { "name" => "ticket.address_house_number", "operator" => "has changed" },
          { "name" => "ticket.address_postcode", "operator" => "has changed" },
          { "name" => "ticket.address_lat", "operator" => "has changed" },
          { "name" => "ticket.address_lon", "operator" => "has changed" },
          { "name" => "ticket.investment", "operator" => "has changed", "value" => [] }
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
  end

  def down
    Webhook.where(name: 'OPS - Nový komentár pre OPS portál').destroy_all
    Webhook.where(name: 'OPS - Upravený podnet pre OPS portál').destroy_all

    Trigger.where(name: 'ops - preposielanie upravených podnetov na portál').destroy_all
    Trigger.where(name: 'ops - preposielanie nových komentárov na portál').destroy_all
  end
end
