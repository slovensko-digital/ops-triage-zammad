class AddUserWebhook < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    # add user.updated webhook
    Webhook.find_or_initialize_by(name: 'OPS - Upravený používateľ').tap do |webhook|
      webhook.endpoint = File.join(ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000'), 'triage/webhook')
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
  end

  def down
    Webhook.where(name: 'OPS - Upravený používateľ').destroy_all
  end
end
