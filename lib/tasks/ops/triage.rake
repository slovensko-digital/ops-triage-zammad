namespace :ops do
  namespace :triage do
    desc "Migrates triage environment"
    task migrate: :environment do
      puts "Migrating triage environment!"
      Setting.set('user_create_account', false) # Disable user creation via web interface

      Setting.set('auth_third_party_auto_link_at_inital_login', true)
      Setting.set('auth_third_party_no_create_user', true)

      Setting.set('customer_ticket_create', false) # disable WEB interface ticket creation
    end
  end
end

Rake::Task['db:migrate'].enhance(['ops:triage:migrate'])
