FROM zammad/zammad-docker-compose:6.4.1-49

# RUN sed -i 's/config.log_level = :info/config.log_level = :debug/' /opt/zammad/config/environments/production.rb

COPY ./config/default /etc/nginx/sites-enabled/default

EXPOSE 3000
EXPOSE 6042

ENTRYPOINT [ "/bin/sh", "-c" ]
CMD [ "/docker-entrypoint.sh", "zammad-railsserver" ]
