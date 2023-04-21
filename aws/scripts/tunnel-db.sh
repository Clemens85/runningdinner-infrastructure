#! /bin/bash

passedStage=$1
if [[ -z "$passedStage" ]]; then
  echo "Error: Must pass a stage as first parameter"
  exit 1
fi

CUR_DIR=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

INFRA_BASE_PATH="../infrastructure"

read -r DB_ENDPOINT < $INFRA_BASE_PATH/database/.db-address-${passedStage}.txt
echo "Using $DB_ENDPOINT"

read -r DNS < $INFRA_BASE_PATH/app/.appserver-ip-${passedStage}.txt
echo "Using $DNS"

cd $CUR_DIR

ssh -L 54321:"$DB_ENDPOINT":5432 ec2-user@"$DNS"