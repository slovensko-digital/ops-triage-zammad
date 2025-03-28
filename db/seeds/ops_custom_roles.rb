responsible_subject_role = Role.find_or_initialize_by(name: 'Zodpovedný Subjekt').tap do |role|
  role.note = __('Zodpovedný Subjekt users.')
  role.default_at_signup = false
  role.preferences = {}
  role.updated_by_id = 1
  role.created_by_id = 1
end
responsible_subject_role.permission_grant('ticket.customer')
responsible_subject_role.save!
