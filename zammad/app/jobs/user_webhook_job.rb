class UserWebhookJob < ApplicationJob
  USER_WEBHOOK_NAME = 'OPS - Upravený používateľ'
  class UserWebhookJob::RequestError < StandardError; end

  retry_on UserWebhookJob::RequestError, attempts: 5, wait: lambda { |executions|
    executions * 10.seconds
  }

  def perform(user)
    return if Setting.get('import_mode')

    webhook = Webhook.find_by(name: USER_WEBHOOK_NAME)
    return if !webhook

    result = UserAgent.post(
      webhook.endpoint,
      { type: 'user.updated', timestamp: DateTime.current, data: { user_id: user.id } },
      {
        json:                    true,
        jsonParseDisable:        true,
        open_timeout:            4,
        read_timeout:            30,
        total_timeout:           60,
        headers:                 headers,
        signature_token:         webhook.signature_token,
        verify_ssl:              webhook.ssl_verify,
        user:                    webhook.basic_auth_username,
        password:                webhook.basic_auth_password,
        do_not_follow_redirects: true,
        log:                     {
          facility: 'webhook',
        },
      },
      )

    raise UserWebhookJob::RequestError if !result.success?
  end

  def headers
    {
      'X-Zammad-Delivery' => job_id
    }
  end
end
