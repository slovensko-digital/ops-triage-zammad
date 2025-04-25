class CreateAgentsAdministratorRole < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    agents_administrator_role = Role.find_or_initialize_by(name: 'Administrátor dobrovoľníkov').tap do |role|
      role.note = __('Na prácu s tiketmi a manažment dobrovoľníkov.')
      role.default_at_signup = false
      role.preferences = {}
      role.updated_by_id = 1
      role.created_by_id = 1
    end
    agents_administrator_role.save!
    agents_administrator_role.permission_grant('chat.agent')
    agents_administrator_role.permission_grant('cti.agent')
    agents_administrator_role.permission_grant('knowledge_base.reader')
    agents_administrator_role.permission_grant('ticket.agent')
    agents_administrator_role.permission_grant('user_preferences')
    agents_administrator_role.save!

  end

  def down
    role = Role.find_by(name: 'Administrátor dobrovoľníkov')
    role.destroy if role
  end
end
