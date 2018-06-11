#! /bin/sh

if [ -z "$ENVIRON" ]; then
    # Development
    export PCW_DB_HOST="db"
    export PCW_DB_USER="postgres"
    export PCW_DB_PASSWORD=""
    export SECRET_KEY_BASE=development
else
    export SECRET_KEY_BASE=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-secret-key-base" | jq -r .Parameter.Value`
    export PCW_DB_PASSWORD=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-database-password" | jq -r .Parameter.Value`
    export PCW_DB_USER=pcw
    export RAILS_ENV=production
    # PCW_DB_HOST should be set through an environment variable
fi
cd /pcw
bundle exec rails s -b 0.0.0.0
