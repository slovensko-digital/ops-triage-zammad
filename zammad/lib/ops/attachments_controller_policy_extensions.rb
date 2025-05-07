module Ops::AttachmentsControllerPolicyExtensions
  def destroy?
    return true if super

    if !user.permissions?('admin.ticket')
      return not_authorized('admin.ticket permission required')
    end

    true
  end
end
