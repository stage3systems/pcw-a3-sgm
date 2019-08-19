#! /bin/sh

psql -U postgres -h db -c 'drop database pcw_test;'
psql -U postgres -h db -c 'create database pcw_test;'
psql -U postgres -h db -c 'create extension hstore;' -d pcw_test
RAILS_ENV=test bundle exec rake db:structure:load
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rake
