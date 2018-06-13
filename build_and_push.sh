#! /bin/sh

if [ -z "$CODEBUILD_RESOLVED_SOURCE_VERSION" ]; then
    # local execution
    REVISION=`git rev-parse HEAD`
    export AWS_PROFILE=a3
else
    # codebuild
    REVISION="$CODEBUILD_RESOLVED_SOURCE_VERSION"
fi

echo "Building and pushing docker images at revision $REVISION"
docker build -t pcw-rails:$REVISION .
docker tag pcw-rails:$REVISION 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-rails:$REVISION
docker build -f Dockerfile.nginx -t pcw-nginx:$REVISION .
docker tag pcw-nginx:$REVISION 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-nginx:$REVISION
aws ecr get-login --region us-west-2 --no-include-email > .login_cmd
. ./.login_cmd
rm ./.login_cmd
docker push 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-rails:$REVISION
docker push 949953444104.dkr.ecr.us-west-2.amazonaws.com/pcw-nginx:$REVISION
