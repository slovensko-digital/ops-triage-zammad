FROM zammad/zammad-docker-compose:stable

# CMD [ "zammad-railsserver" ]
# CMD [ "bin/rails", "db:migrate", ";", "bin/rails", "s" ]
CMD bin/rails db:migrate;bin/rails s
