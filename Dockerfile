FROM ruby:2.3

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev \
        libxml2-dev libxslt1-dev nodejs python3-pip jq gzip

RUN apt-get update && apt-get install -y wget gnupg
RUN mkdir -p /usr/share/man/man1 \
    && mkdir -p /usr/share/man/man7
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN printf "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y postgresql-client-common postgresql-client-11

RUN pip3 install awscli

# Cleanup
RUN apt-get clean autoclean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

WORKDIR /pcw

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY app app/
COPY bin bin/
COPY config config/
COPY config.ru ./
COPY db db/
COPY fonts fonts/
COPY lib lib/
COPY public public/
COPY Rakefile ./
COPY script script/
COPY vendor vendor/
COPY start_server.sh ./
COPY start_job_queue.sh ./
COPY rails_console.sh ./
COPY backup.sh ./
RUN mkdir -p pdfs
RUN mkdir -p sheets
RUN mkdir -p log


# Download and extract the GeoCity db
ADD http://static.stage3systems.com/pcw/GeoLiteCity.dat.gz ./
RUN gunzip GeoLiteCity.dat.gz

RUN RAILS_ENV=production bundle exec rake assets:precompile

VOLUME ["/pcw/public"]

EXPOSE 3000

CMD ["/pcw/start_server.sh"]
