#! /bin/sh

if [ -z "$ENVIRON" ]; then
    # Development
    export PCW_DB_HOST="db"
    export PCW_DB_USER="postgres"
    export PCW_DB_PASSWORD=""
    # Handle dev secrets in that file (not in git)
    if [ -f ".env" ]; then
        . ./.env
    fi
else
    export PCW_DB_PASSWORD=`aws ssm get-parameter --with-decryption --region us-west-2 --name "pcw-$ENVIRON-database-password" | jq -r .Parameter.Value`
    export PCW_DB_USER=pcw
    # PCW_DB_HOST should be set through an environment variable
fi
echo "PCW ${ENVIRON} backup starting"
BACKUP_NAME="pcw_${ENVIRON}_`date +%Y%m%d%H%M`.sql.bz2"
PGPASSWORD="$PCW_DB_PASSWORD" pg_dump -U $PCW_DB_USER -h $PCW_DB_HOST pcw | bzip2 - > /tmp/$BACKUP_NAME
aws s3 cp /tmp/$BACKUP_NAME s3://$TARGET_BUCKET/backups/pcw/$BACKUP_NAME
aws s3 cp /tmp/$BACKUP_NAME s3://$TARGET_BUCKET/backups/pcw/pcw_${ENVIRON}.sql.bz2
rm /tmp/$BACKUP_NAME
echo "PCW ${ENVIRON} backup complete to s3://$TARGET_BUCKET/backups/pcw/$BACKUP_NAME"
