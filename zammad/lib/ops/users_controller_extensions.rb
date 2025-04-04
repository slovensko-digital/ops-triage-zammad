module Ops::UsersControllerExtensions
  def update
    super

    UserWebhookJob.perform_later(User.find(params[:id]))
  end
end
