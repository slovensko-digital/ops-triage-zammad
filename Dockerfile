FROM zammad/zammad-docker-compose:6.4.1-49

# RUN sed -i 's/config.log_level = :info/config.log_level = :debug/' /opt/zammad/config/environments/production.rb

# append ops_custom_fields to the end of the list
RUN sed -i 's/\(seeds = %w\[.*\)\]/\1 ops_custom_fields]/' db/seeds.rb

COPY --chown=zammad:zammad ./config/nginx.conf /etc/nginx/sites-enabled/default
COPY --chown=zammad:zammad ./zammad_init_and_nginx.sh /opt/zammad_init_and_nginx.sh

COPY ./db/migrate/* ./db/migrate/.
COPY ./db/seeds/* ./db/seeds/.
COPY ./lib/tasks/ops/triage.rake ./lib/tasks/ops/triage.rake

EXPOSE 3000
EXPOSE 6042

CMD [ "zammad-railsserver" ]
