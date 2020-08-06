#! /bin/sh

if [ -z "$ENVIRON" ]; then
    # Development
    export PCW_DB_HOST="db"
    export PCW_DB_USER="postgres"
    export PCW_DB_PASSWORD=""
    export SECRET_KEY_BASE=development
    PCW_AUTH0_DOMAIN=''
    PCW_AUTH0_CLIENT_ID=''
    # Handle dev secrets in that file (not in git)
    if [ -f ".env" ]; then
        . ./.env
    fi

    export PCW_AUTH0_DOMAIN=$PCW_AUTH0_DOMAIN
    export PCW_AUTH0_CLIENT_ID=$PCW_AUTH0_CLIENT_ID
else
    export SECRET_KEY_BASE=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-secret-key-base" | jq -r .Parameter.Value`
    export PCW_DB_PASSWORD=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-database-password" | jq -r .Parameter.Value`
    export PCW_AUTH0_DOMAIN=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-auth0-domain" | jq -r .Parameter.Value`
    export PCW_AUTH0_CLIENT_ID=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-auth0-client-id" | jq -r .Parameter.Value`
    export PCW_DB_USER=pcw
    export RAILS_ENV=production
    export PCW_AWS_USE_IAM_PROFILE=true
    # PCW_DB_HOST should be set through an environment variable
fi
cd /pcw
rm -f /pcw/tmp/pids/server.pid

bundle exec rake db:migrate
bundle exec rake db:schema:cache:dump
bundle exec rails s -b 0.0.0.0
