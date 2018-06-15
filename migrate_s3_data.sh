#! /bin/sh

mkdir -p .s3_tmp_data
function sync_tenant() {
    mkdir -p .s3_tmp_data/$1
    AWS_PROFILE=s3s aws s3 sync s3://s3s-or/$1/pce ./.s3_tmp_data/$1/pcw
    AWS_PROFILE=a3 aws s3 sync ./.s3_tmp_data/$1/pcw s3://a3-customer-data/$1/pcw
}

sync_tenant "monson"
