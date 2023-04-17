#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

# Set the name of the IAM user
USERNAME=ci_user

# Query for an existing access key and delete it (if existing):
KEYS=$(aws iam list-access-keys --user-name $USERNAME --output json)
ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKeyMetadata[0].AccessKeyId')
if [[ -n "$ACCESS_KEY" ]]; then
  echo "Deleting Access token $ACCESS_KEY"
  aws iam delete-access-key --user-name $USERNAME --access-key-id $ACCESS_KEY
fi

source clear-aws-cli.sh

cd $CUR_DIR_TF