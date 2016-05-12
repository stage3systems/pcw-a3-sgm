#! /bin/sh

export RAILS_ENV=production
sudo service pce stop || true
sudo chown -R ubuntu:ubuntu /home/ubuntu
cd /home/ubuntu/pce
cp /home/ubuntu/config/*.yml config/
bundle check || bundle install
bundle exec rake db:migrate
sudo service pce start
