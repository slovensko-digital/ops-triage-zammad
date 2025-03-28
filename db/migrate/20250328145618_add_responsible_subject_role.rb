class AddResponsibleSubjectRole < ActiveRecord::Migration[6.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    new_role = Role.find_or_initialize_by(name: 'Zodpovedný Subjekt').tap do |role|
      role.note = __('Zodpovedný Subjekt')
      role.default_at_signup = false
      role.preferences = {}
      role.updated_by_id = 1
      role.created_by_id = 1
    end
    new_role.permission_grant('ticket.customer')

    new_role.save!
  end

  def down
    Role.find_by(name: 'Zodpovedný Subjekt')&.destroy
  end
end
