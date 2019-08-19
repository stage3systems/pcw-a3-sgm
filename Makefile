restore-dump:
	@docker-compose run pcw psql -U postgres -h db -f cycle_db.sql
	@docker-compose run pcw psql -U postgres -h db pcw -f pcw.stg.sql

pcw.stg.sql:
	@AWS_PROFILE=a3 aws s3 cp s3://a3-dumps/pcw.stg.sql.bz2 .
	@bunzip2 pcw.stg.sql.bz2

dev:
	@docker-compose build
	@docker-compose up

GeoLiteCity.dat:
	@curl -O http://static.stage3systems.com/pcw/GeoLiteCity.dat.gz
	@gunzip GeoLiteCity.dat.gz

t: GeoLiteCity.dat
	@docker-compose run pcw ./wait-for-it.sh db:5432 -- ./run_tests.sh

docker-shell:
	@docker-compose exec pcw bash

ruby-shell:
	@docker-compose exec pcw ./rails_console.sh
