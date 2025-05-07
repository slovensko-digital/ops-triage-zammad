ActiveSupport.on_load(:after_initialize) do
  UsersController.prepend Ops::UsersControllerExtensions

  Controllers::AttachmentsControllerPolicy.prepend Ops::AttachmentsControllerPolicyExtensions
end
