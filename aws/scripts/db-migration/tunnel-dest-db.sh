#! /bin/bash

CUR_DIR=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

INFRA_BASE_PATH="../../infrastructure"

read -r DB_ENDPOINT < $INFRA_BASE_PATH/database/.db-address.txt
echo "Using $DB_ENDPOINT"

read -r DNS < $INFRA_BASE_PATH/app/.appserver-ip.txt
echo "Using $DNS"

cd $CUR_DIR

ssh -L 54321:"$DB_ENDPOINT":5432 ec2-user@"$DNS"