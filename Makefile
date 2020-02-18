download-db:
	@rm pcw_${ENV}.sql*
	@AWS_PROFILE=a3 aws s3 cp s3://a3-dumps/development/pcw_${ENV}.sql.bz2 .
	@bunzip2 pcw_${ENV}.sql.bz2

restore-dump: download-db
	@docker-compose run pcw psql -U postgres -h db -f cycle_db.sql
	@docker-compose run pcw psql -U postgres -h db pcw -f pcw_${ENV}.sql

load-dev-db: download-db
	@cat pcw_${ENV}.sql |docker-compose exec -T db psql -d pcw -U webadmin

dev:
	@docker-compose build
	@docker-compose up

GeoLiteCity.dat:
	@curl -O http://static.stage3systems.com/pcw/GeoLiteCity.dat.gz
	@gunzip GeoLiteCity.dat.gz

docker-build-clear:
	@docker-compose build --no-cache
	@docker-compose down
	@docker-compose up -d

t: GeoLiteCity.dat
	@docker-compose run pcw ./wait-for-it.sh db:5432 -- ./run_tests.sh

docker-shell:
	@docker-compose exec pcw bash

ruby-shell:
	@docker-compose exec pcw ./rails_console.sh
