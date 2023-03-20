#! /bin/bash

# env -i bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

NAME="$2"
VALUE="$3"

aws ssm put-parameter --name "$NAME" \
                      --type "SecureString" \
                      --value "${VALUE}" \
                      --overwrite

source clear-aws-cli.sh

cd $CUR_DIR_TF