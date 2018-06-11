#! /bin/sh

case "$1" in
    "stg")
        ;;
    "prd")
        ;;
    *)
        echo "Please specify an environment (stg or prd)"
        exit 1
        ;;
esac
REVISION=`git rev-parse HEAD`
echo "Building and pushing $1 docker image at revision $REVISION"
docker build -t pcw-$1 .
docker tag pcw-$1:latest 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-$1:latest
AWS_PROFILE=a3 aws ecr get-login --region us-west-2 --no-include-email > .login_cmd
. ./.login_cmd
rm ./.login_cmd
docker push 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-$1:latest
