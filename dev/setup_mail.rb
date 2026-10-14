# Local development only. Run once after `docker compose up`, with the portal running:
#
#   docker compose exec zammad-railsserver bundle exec rails r /opt/ops-dev/setup_mail.rb
#
# Makes local Triage send the emails it sends in production, so they can be checked in Mailpit:
# 1. An email channel for the system email address, set on every group. Without it Zammad skips
#    trigger emails. Outbound goes to Mailpit (dev/mail_catcher.rb redirects it there anyway).
# 2. For every active responsible subject in the portal, an organization with the same name and a
#    fake recipient with the "Externý zodpovedný subjekt" role. Those are the recipients of the
#    "preposielanie - Zodpovedný subjekt" triggers (Ops::TicketPerformChangesActionNotificationEmailExtensions).
#
# Safe to run again, e.g. after new responsible subjects are added in the portal.
require 'net/http'

channel = Channel.find_or_initialize_by(area: 'Email::Account')
channel.update!(
  options:       {
    inbound:  { adapter: 'null', options: {} },
    outbound: { adapter: 'smtp', options: { host: 'zammad-mailpit', port: 1025, ssl: false, enable_starttls_auto: false } },
  },
  active:        true,
  preferences:   {},
  created_by_id: 1,
  updated_by_id: 1
)

# the production address, responsible_subjects:activate_basic in the portal expects it
address = EmailAddress.find_or_initialize_by(email: 'podnety@triaz.odkazprestarostu.sk')
address.update!(name: ENV.fetch('PRODUCT_NAME', 'Triáž'), channel_id: channel.id, active: true, created_by_id: 1, updated_by_id: 1)
Group.where(email_address_id: nil).update_all(email_address_id: address.id) # rubocop:disable Rails/SkipsModelValidations
puts "Email channel #{channel.id} sends as #{address.email} for all groups"

portal_url = ENV.fetch('OPS_PORTAL_URL')
begin
  response = Net::HTTP.get_response(URI(File.join(portal_url, 'api/v1/responsible_subjects')))
  raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
rescue => e
  abort "Can't load responsible subjects from #{portal_url} (#{e.message}), is the portal running?"
end

role = Role.find_by!(name: 'Externý zodpovedný subjekt')
subjects = JSON.parse(response.body)

skipped = 0

subjects.each do |subject|
  login = "dev-rs-#{subject['id']}"

  # leave organizations set up otherwise alone, e.g. by responsible_subjects:activate_basic
  if Organization.exists?(name: subject['name']) && !User.exists?(login: login)
    skipped += 1
    next
  end

  organization = Organization.find_or_initialize_by(name: subject['name'])
  organization.update!(active: true, created_by_id: 1, updated_by_id: 1)

  user = User.find_or_initialize_by(login: login)
  user.update!(
    firstname:     subject['name'],
    lastname:      'test',
    email:         "rs-#{subject['id']}@responsible-subject.example",
    active:        true,
    organization:  organization,
    roles:         [role],
    created_by_id: 1,
    updated_by_id: 1
  )
end

puts "#{subjects.count - skipped} responsible subjects receive emails at rs-<portal id>@responsible-subject.example, " \
     "#{skipped} skipped (organization already set up)"
