FROM node:20-bookworm-slim AS node
RUN npm -g install corepack && corepack enable pnpm
RUN rm /usr/local/bin/yarn /usr/local/bin/yarnpkg


FROM zammad/zammad-docker-compose:6.5.0-47

RUN sed -i 's/config.log_level = :info/config.log_level = ENV.fetch("RAILS_LOG_LEVEL", :info)/' /opt/zammad/config/environments/production.rb

# append custom seeds to the end of the list
RUN sed -i 's/\(seeds = %w\[.*\)\]/\1 ops_custom_settings ops_custom_roles ops_custom_user_fields ops_custom_ticket_fields ops_custom_webhooks]/' db/seeds.rb

# allow creation of customer articles in triggers
RUN sed -i "s/Ticket::Article::Sender.find_by(name: 'System')/Ticket::Article::Sender.find_by(name: note[:sender] || 'System')/" app/models/ticket/perform_changes/action/article_note.rb

COPY --chown=zammad:zammad ./zammad_init_and_railsserver.sh /opt/zammad_init_and_railsserver.sh

RUN mkdir hacks
COPY ./hacks/* ./hacks/.
RUN hacks/hacks.rb

COPY zammad ./

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin /usr/local/bin
USER root
RUN bundle install && \
    ZAMMAD_SAFE_MODE=1 DATABASE_URL=postgresql://zammad:/zammad bundle exec rake assets:precompile

EXPOSE 3000
EXPOSE 6042

CMD [ "zammad-railsserver" ]
