FROM zammad/zammad-docker-compose:6.5.0-47

RUN sed -i 's/config.log_level = :info/config.log_level = ENV.fetch("RAILS_LOG_LEVEL", :info)/' /opt/zammad/config/environments/production.rb

# append custom seeds to the end of the list
RUN sed -i 's/\(seeds = %w\[.*\)\]/\1 ops_custom_roles ops_custom_user_fields ops_custom_ticket_fields ops_custom_webhooks ops_custom_triggers]/' db/seeds.rb

# allow creation of customer articles in triggers
RUN sed -i "s/Ticket::Article::Sender.find_by(name: 'System')/Ticket::Article::Sender.find_by(name: note[:sender] || 'System')/" app/models/ticket/perform_changes/action/article_note.rb

COPY --chown=zammad:zammad ./config/nginx.conf /etc/nginx/sites-enabled/default
COPY --chown=zammad:zammad ./zammad_init_and_nginx.sh /opt/zammad_init_and_nginx.sh

COPY zammad ./

EXPOSE 3000
EXPOSE 6042

CMD [ "zammad-railsserver" ]
