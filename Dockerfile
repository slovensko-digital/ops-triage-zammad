FROM zammad/zammad-docker-compose:stable

# CMD [ "zammad-railsserver" ]
CMD bin/rails db:seed;bin/rails s
