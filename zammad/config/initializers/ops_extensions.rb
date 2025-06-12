ActiveSupport.on_load(:after_initialize) do
  UsersController.prepend Ops::UsersControllerExtensions
  Controllers::AttachmentsControllerPolicy.prepend Ops::AttachmentsControllerPolicyExtensions
  Ticket::Article::TriggersSubscriptions.prepend Ops::TicketArticleTriggersSubscriptionsExtensions
  User.prepend Ops::UserExtensions
  Ticket::PerformChanges::Action::NotificationEmail.prepend Ops::TicketPerformChangesActionNotificationEmailExtensions
  Ticket::Article.prepend Ops::TicketArticleExtensions
end
