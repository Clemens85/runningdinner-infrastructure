#! /bin/bash

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

aws resourcegroupstaggingapi get-resources --tag-filters Key=service,Values=runningdinner-v2

source clear-aws-cli.sh

cd $CUR_DIR_TF