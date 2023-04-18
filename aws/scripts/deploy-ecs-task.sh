#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

aws ecs update-service --cluster runningdinner-ecs-cluster --service runningdinner-service --task-definition runningdinner-backend \
                       --deployment-configuration "minimumHealthyPercent=0" --desired-count 1 \
                       --force-new-deployment


source clear-aws-cli.sh

cd $CUR_DIR_TF