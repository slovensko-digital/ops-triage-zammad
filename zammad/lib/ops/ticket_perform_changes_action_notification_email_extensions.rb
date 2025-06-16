module Ops::TicketPerformChangesActionNotificationEmailExtensions
  def recipients_by_type(recipient_type)
    label = record.responsible_subject["label"]
    return nil unless label.present?

    if recipient_type =~ %r{\Auserid_(\d+)\z}
      # check if special responsible subject user is set to trigger this action
      return nil unless User.where(login: "template-ext", id: $1).exists?

      org = Organization.find_by(name: label, active: true)
      return nil unless org

      role = Role.find_by(name: "Externý zodpovedný subjekt")
      unless role
        Rails.logger.error("Role 'Externý zodpovedný subjekt' not found, cannot send email to responsible subject")
        return nil
      end

      return role.users.where(active: true, organization: org).pluck(:email).compact
    end

    super
  end
end
