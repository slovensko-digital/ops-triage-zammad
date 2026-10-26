# Local development only, run by dev/setup.rb.
#
# Adds what responsible_subjects:activate_basic in the portal needs to activate a municipality:
#   - an API token of the admin (ADMIN_EMAIL) with ADMIN_API_TOKEN as its value. The portal's API_TOKEN
#     cannot manage roles, organizations and triggers. The portal .env.sample has it as
#     TRIAGE_ZAMMAD_ADMIN_API_TOKEN,
#   - the volunteer dobrovolnik@example.org (password ADMIN_PASSWORD), the agent the portal passes as
#     TRIAGE_ZAMMAD_AGENT_EMAIL. Like volunteers in production, they have no access to the Incoming group,
#     the activation gives them the municipality's group.
#
# Safe to run again.
admin = User.find_by!(email: ENV.fetch('ADMIN_EMAIL'))

token = Token.find_or_initialize_by(name: 'Local dev admin token for responsible_subjects:activate_basic', user_id: admin.id)
token.action = 'api'
token.persistent = true
token.preferences = { 'permission' => %w[admin.group admin.organization admin.role admin.trigger admin.user ticket.agent] }
token.save!
# Zammad replaces the value with a random one on create, see API_TOKEN in zammad/lib/tasks/ops/triage.rake
admin_api_token = ENV.fetch('ADMIN_API_TOKEN')
token.update!(token: admin_api_token) if token.token != admin_api_token

volunteer = User.find_or_initialize_by(email: 'dobrovolnik@example.org')
volunteer.assign_attributes(
  login:         volunteer.email,
  firstname:     'Dobrovoľník',
  lastname:      'Testovací',
  active:        true,
  roles:         [Role.find_by!(name: 'Agent')],
  updated_by_id: 1,
  created_by_id: 1
)
volunteer.password = ENV.fetch('ADMIN_PASSWORD') if volunteer.new_record?
volunteer.save!

puts "Admin #{admin.email} has the admin API token, volunteer #{volunteer.email} (#{volunteer.id}) is an agent"
