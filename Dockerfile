FROM zammad/zammad-docker-compose:6.4.1-49

# RUN sed -i 's/config.log_level = :info/config.log_level = :debug/' /opt/zammad/config/environments/production.rb

COPY --chown=zammad:zammad ./config/nginx.conf /etc/nginx/sites-enabled/default

COPY ./lib/tasks/ops/triage.rake ./lib/tasks/ops/triage.rake

EXPOSE 3000
EXPOSE 6042

CMD [ "zammad-railsserver" ]
