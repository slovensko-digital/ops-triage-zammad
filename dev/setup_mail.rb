# Local development only, run by dev/setup.rb on every `docker compose up`.
#
# Zammad sends trigger emails (e.g. "preposielanie - Zodpovedný subjekt") only from the group's
# email address, and only when that address has an email channel. A fresh install has neither,
# so the emails are skipped ("no channel is set for email address" in the log). This adds the
# channel, so they show up in Mailpit (dev/mail_catcher.rb redirects all delivery there anyway).
#
# Safe to run again.
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
