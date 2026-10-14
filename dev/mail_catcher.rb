# Local development only. docker-compose.yml mounts this file into config/initializers,
# it is never part of the image deployed by Kamal.
#
# Routes every outgoing email (notifications and email channels, whatever their SMTP
# settings in the database) to the mail catcher (Mailpit), so local Triage never sends
# real emails. Active only when MAIL_CATCHER_SMTP (host:port) is set.
if ENV['MAIL_CATCHER_SMTP'].present?
  Rails.application.config.after_initialize do
    host, port = ENV.fetch('MAIL_CATCHER_SMTP').split(':')

    catcher = Module.new do
      define_method(:deliver) do |_options, attr, notification = false|
        return if Setting.get('import_mode')

        attr = prepare_message_attrs(attr, notification)
        mail = Channel::EmailBuild.build(attr, notification)
        mail.delivery_method :smtp, address: host, port: (port || 1025).to_i, enable_starttls_auto: false
        mail.deliver
      end
    end

    [Channel::Driver::Smtp, Channel::Driver::Sendmail, Channel::Driver::MicrosoftGraphOutbound].each do |driver|
      driver.prepend(catcher)
    end

    Rails.logger.info "Mail catcher: all outgoing emails go to #{host}:#{port}"
  end
end
