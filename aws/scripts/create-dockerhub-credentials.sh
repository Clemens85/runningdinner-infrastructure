#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

USERNAME="$2"
PASSWORD="$3"
EMAIL="$4"

if [[ -z "$USERNAME" ]]; then
  echo "Error: Must pass the username as 2. param"
  exit 1
fi
if [[ -z "$PASSWORD" ]]; then
  echo "Error: Must pass the password as 3. param"
  exit 1
fi
if [[ -z "$EMAIL" ]]; then
  echo "Error: Must pass the email as 4. param"
  exit 1
fi

aws ssm put-parameter --name "/runningdinner/dockerhub/credentials" \
                      --type "SecureString" \
                      --value "{\"https://index.docker.io/v1/\":{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\"}}" \
                      --overwrite

source clear-aws-cli.sh

cd $CUR_DIR_TF