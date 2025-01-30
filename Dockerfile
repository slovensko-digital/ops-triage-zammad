FROM zammad/zammad-docker-compose:stable

RUN sed -i 's/config.log_level = :info/config.log_level = :debug/' /opt/zammad/config/environments/production.rb

CMD [ "zammad-railsserver" ]
