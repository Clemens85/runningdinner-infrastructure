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

# Now create a new one and extract the token values:
KEYS=$(aws iam create-access-key --user-name $USERNAME --output json)
ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $KEYS | jq -r '.AccessKey.SecretAccessKey')

# Print the access key ID and secret access key to the terminal
echo "Access Key ID: $ACCESS_KEY"
echo "Secret Access Key: $SECRET_KEY"

source clear-aws-cli.sh

cd $CUR_DIR_TF