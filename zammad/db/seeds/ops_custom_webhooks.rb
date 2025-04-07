# add ticket.created webhook
Webhook.find_or_initialize_by(name: 'OPS - Nový podnet pre zodpovedný subjekt').tap do |webhook|
  webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject')
  webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
  webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
  webhook.note = "Slúži na preposielanie nových podnetov z triáže zapojeným zodpovedným subjektom"
  webhook.customized_payload = true
  webhook.custom_payload = {
    "type" => "ticket.created",
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

# add article.created webhook
Webhook.find_or_initialize_by(name: 'OPS - Nový komentár pre zodpovedný subjekt').tap do |webhook|
  webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject')
  webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
  webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
  webhook.note = "Slúži na preposielanie nových komentárov z triáže zapojeným zodpovedným subjektom"
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

# add ticket.updated webhook
Webhook.find_or_initialize_by(name: 'OPS - Upravený podnet pre zodpovedný subjekt').tap do |webhook|
  webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject')
  webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
  webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
  webhook.note = "Slúži na preposielanie úprav podnetov z triáže zapojeným zodpovedným subjektom"
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

# add user.updated webhook
Webhook.find_or_initialize_by(name: 'OPS - Upravený používateľ').tap do |webhook|
  webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal')
  webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
  webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
  webhook.note = "Slúži na preposielanie úprav používateľov z triáže"
  webhook.customized_payload = true
  webhook.custom_payload = {}.to_json
  webhook.preferences = {}
  webhook.active = true
  webhook.updated_by_id = 1
  webhook.created_by_id = 1
end.save!

# add article.created portal webhook
Webhook.find_or_initialize_by(name: 'OPS - Nový komentár pre OPS portál').tap do |webhook|
  webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal')
  webhook.signature_token = ENV.fetch('WEBHOOK_SECRET', Random.hex(32))
  webhook.ssl_verify = ENV.fetch('OPS_PORTAL_URL', 'http').start_with?('https')
  webhook.note = "Slúži na preposielanie nových komentárov na portál Odkazu pre starostu"
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
