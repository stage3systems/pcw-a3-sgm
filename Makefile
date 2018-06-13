restore-dump: pcw.sql
	@docker-compose run pcw psql -U postgres -h db -f cycle_db.sql
	@docker-compose run pcw psql -U postgres -h db pcw -f pcw.sql

pcw.sql:
	@AWS_PROFILE=a3 aws s3 cp s3://a3-dumps/pcw.sql.bz2 .
	@bunzip2 pcw.sql.bz2

dev:
	@docker-compose build
	@docker-compose up

GeoLiteCity.dat:
	@curl -O http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
	@gunzip GeoLiteCity.dat.gz

t: GeoLiteCity.dat
	@docker-compose run pcw psql -U postgres -h db -c 'drop database pcw_test;'
	@docker-compose run pcw psql -U postgres -h db -c 'create database pcw_test;'
	@docker-compose run pcw psql -U postgres -h db -c 'create extension hstore;' -d pcw_test
	@docker-compose run -e RAILS_ENV=test pcw bundle exec rake db:structure:load
	@docker-compose run -e RAILS_ENV=test pcw bundle exec rake db:migrate
	@docker-compose run pcw bundle exec rake
