class Controllers::Ops::OwnerHandoverRunsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin')
end
