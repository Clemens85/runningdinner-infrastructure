#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

# Set the name of the IAM user
USERNAME=ci_user

# Generate the access key ID and secret access key for the IAM user
KEYS=$(aws iam create-access-key --user-name $USERNAME --output json)

# Extract the access key ID and secret access key from the response JSON
ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $KEYS | jq -r '.AccessKey.SecretAccessKey')

# Print the access key ID and secret access key to the terminal
echo "Access Key ID: $ACCESS_KEY"
echo "Secret Access Key: $SECRET_KEY"

source clear-aws-cli.sh

cd $CUR_DIR_TF