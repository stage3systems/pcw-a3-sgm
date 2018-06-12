FROM ruby:2.3

RUN apt-get update -qq && apt-get install -y build-essential

RUN apt-get install -y libpq-dev postgresql-client

RUN apt-get install -y libxml2-dev libxslt1-dev

RUN apt-get install -y nodejs

RUN apt-get install -y python3-pip

RUN pip3 install awscli

RUN apt-get install -y jq

# Cleanup
RUN apt-get clean autoclean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

ENV APP_HOME /pcw

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

# Download and extract the GeoCity db
RUN curl -O http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
RUN gunzip GeoLiteCity.dat.gz

COPY Gemfile Gemfile.lock ./

RUN bundle install

EXPOSE 3000

ADD . $APP_HOME
RUN RAILS_ENV=production bundle exec rake assets:precompile

VOLUME ["/pcw/public"]

CMD ["/pcw/start_server.sh"]
