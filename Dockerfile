FROM ruby:2.3

RUN apt-get update -qq && apt-get install -y build-essential

RUN apt-get install -y libpq-dev postgresql-client

RUN apt-get install -y libxml2-dev libxslt1-dev

RUN apt-get install -y nodejs


ENV APP_HOME /pcw

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

# Download and extract the GeoCity db
RUN curl -O http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
RUN gunzip GeoLiteCity.dat.gz

COPY Gemfile Gemfile.lock ./

RUN bundle install

ADD . $APP_HOME
RUN RAILS_ENV=production bundle exec rake assets:precompile

CMD start_server.sh
