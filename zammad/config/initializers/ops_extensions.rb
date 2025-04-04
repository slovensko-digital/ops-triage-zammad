ActiveSupport.on_load(:after_initialize) do
  UsersController.prepend Ops::UsersControllerExtensions
end
