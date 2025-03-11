namespace :ops do
  namespace :triage do
    desc "Migrates triage environment"
    task migrate: :environment do
      if User.any?
        puts "Migrating triage environment..."
        Setting.set('user_create_account', false) # Disable user creation via web interface

        Setting.set('auth_third_party_auto_link_at_inital_login', true)
        Setting.set('auth_third_party_no_create_user', true)

        Setting.set('customer_ticket_create', false) # disable WEB interface ticket creation

        Role.where(name: 'Customer').first!.permissions.destroy_all # disable everything
      end
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task[ 'ops:triage:migrate' ].execute
end

Rake::Task['db:seed'].enhance do
  Rake::Task[ 'ops:triage:migrate' ].execute
end
