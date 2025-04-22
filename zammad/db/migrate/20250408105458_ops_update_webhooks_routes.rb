class OpsUpdateWebhooksRoutes < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Webhook.find_by(name: 'OPS - Nový podnet pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/responsible_subject'))
    Webhook.find_by(name: 'OPS - Nový komentár pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/responsible_subject'))
    Webhook.find_by(name: 'OPS - Upravený podnet pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/responsible_subject'))
    Webhook.find_by(name: 'OPS - Upravený používateľ')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/portal'))
    Webhook.find_by(name: 'OPS - Nový komentár pre OPS portál')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/portal'))
    Webhook.find_by(name: 'OPS - Upravený podnet pre OPS portál')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhooks/portal'))
  end

  def down
    Webhook.find_by(name: 'OPS - Nový podnet pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject'))
    Webhook.find_by(name: 'OPS - Nový komentár pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject'))
    Webhook.find_by(name: 'OPS - Upravený podnet pre zodpovedný subjekt')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/responsible_subject'))
    Webhook.find_by(name: 'OPS - Upravený používateľ')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal'))
    Webhook.find_by(name: 'OPS - Nový komentár pre OPS portál')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal'))
    Webhook.find_by(name: 'OPS - Upravený podnet pre OPS portál')&.update(endpoint: File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook/portal'))
  end
end
