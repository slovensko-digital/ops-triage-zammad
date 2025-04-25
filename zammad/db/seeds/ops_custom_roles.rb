responsible_subject_role = Role.find_or_initialize_by(name: 'Zodpovedný Subjekt').tap do |role|
  role.id = 4
  role.note = __('NEMENIŤ! Používa sa pre používateľov "Zodpovedný Subjekt".')
  role.default_at_signup = false
  role.preferences = {}
  role.updated_by_id = 1
  role.created_by_id = 1
end
responsible_subject_role.permission_grant('ticket.customer')
responsible_subject_role.save!

agents_administrator_role = Role.find_or_initialize_by(name: 'Administrátor dobrovoľníkov').tap do |role|
  role.id = 5
  role.note = __('Na prácu s tiketmi a manažment dobrovoľníkov.')
  role.default_at_signup = false
  role.preferences = {}
  role.updated_by_id = 1
  role.created_by_id = 1
end
agents_administrator_role.permission_grant('chat.agent')
agents_administrator_role.permission_grant('cti.agent')
agents_administrator_role.permission_grant('knowledge_base.reader')
agents_administrator_role.permission_grant('ticket.agent')
agents_administrator_role.permission_grant('user_preferences')
agents_administrator_role.save!
