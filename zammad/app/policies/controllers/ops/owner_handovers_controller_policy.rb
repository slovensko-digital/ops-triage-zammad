class Controllers::Ops::OwnerHandoversControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin')
end
