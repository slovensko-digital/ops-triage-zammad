class ArticleUpdatedWebhookJob < ApplicationJob
  ARTICLE_WEBHOOK_NAME = 'OPS - Upravený komentár'
  class ArticleUpdatedWebhookJob::RequestError < StandardError; end

  retry_on ArticleUpdatedWebhookJob::RequestError, attempts: 5, wait: lambda { |executions|
    executions * 10.seconds
  }

  def perform(article)
    webhook = Webhook.find_by(name: ARTICLE_WEBHOOK_NAME)
    return if !webhook

    result = UserAgent.post(
      webhook.endpoint,
      {
        type: 'article.updated',
        timestamp: article.updated_at,
        data: {
          ticket_id: article.ticket_id,
          article_id: article.id
        }
      },
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

    raise ArticleUpdatedWebhookJob::RequestError if !result.success?
  end

  def headers
    {
      'X-Zammad-Delivery' => job_id
    }
  end
end
