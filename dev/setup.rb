# Local development only. The zammad-dev-setup service in docker-compose.yml runs it on every
# `docker compose up`, after zammad-init. Each script is safe to run again.
load File.join(__dir__, 'setup_mail.rb')
load File.join(__dir__, 'setup_users.rb')
