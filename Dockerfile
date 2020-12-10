FROM ruby:2.6

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
RUN apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

WORKDIR /pcw

COPY Gemfile Gemfile.lock ./ 
RUN bundle config set without development test && \
  bundle install --jobs=8

COPY . ./
RUN mkdir -p pdfs && \
  mkdir -p sheets && \
  mkdir -p log


VOLUME ["/pcw/public"]

EXPOSE 3000

CMD ["/pcw/start_server.sh"]
