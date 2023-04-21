#! /bin/bash

passedStage=$1
if [[ -z "$passedStage" ]]; then
  echo "Error: Must pass a stage as first parameter"
  exit 1
fi

CUR_DIR=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

read -r DNS < ../infrastructure/app/.appserver-ip-${passedStage}.txt
echo "Using $DNS"

cd $CUR_DIR

ssh ec2-user@"$DNS"