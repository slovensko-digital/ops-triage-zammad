module Ops::TicketArticleTriggersSubscriptionsExtension
  def trigger_update_subscriptions
    ArticleUpdatedWebhookJob.perform_later(self)
    super
  end
end
