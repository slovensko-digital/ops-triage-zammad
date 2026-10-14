# Local development only. docker-compose.yml mounts this file into config/initializers,
# it is never part of the image deployed by Kamal.
#
# Routes every outgoing email to the mail catcher (Mailpit), so local Triage never sends
# real emails. Zammad delivers all outbound email (SMTP, Sendmail and Microsoft Graph
# channels, whatever their settings in the database) through Mail::Message#deliver, which
# runs the interceptors first. Active only when MAIL_CATCHER_SMTP (host:port) is set.
if ENV['MAIL_CATCHER_SMTP'].present?
  host, port = ENV.fetch('MAIL_CATCHER_SMTP').split(':')

  Mail.register_interceptor(Module.new do
    define_singleton_method(:delivering_email) do |mail|
      mail.delivery_method :smtp, address: host, port: (port || 1025).to_i, enable_starttls_auto: false
    end
  end)

  Rails.logger.info "Mail catcher: all outgoing emails go to #{host}:#{port}"
end
