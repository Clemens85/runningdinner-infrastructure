#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

NAME="$2"
VALUE="$3"

if [[ -z "$NAME" ]]; then
  echo "Error: Must pass the name as 2. param"
  exit 1
fi
if [[ -z "$VALUE" ]]; then
  echo "Error: Must pass the value as 3. param"
  exit 1
fi

aws ssm put-parameter --name "$NAME" \
                      --type "SecureString" \
                      --value "${VALUE}" \
                      --overwrite

source clear-aws-cli.sh

cd $CUR_DIR_TF