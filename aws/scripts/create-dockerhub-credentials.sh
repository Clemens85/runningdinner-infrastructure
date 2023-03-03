#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

passedStage=$1
if [[ -z "$passedStage" ]]; then
  echo "Error: Must pass a stage as first parameter"
  exit 1
fi

USERNAME="$2"
PASSWORD="$3"
EMAIL="$4"

configDir="../config"
awsAccountId=$(grep aws_account_id "${configDir}/stages/${passedStage}/default.tfvars" | awk -F= '{print $2}' | tr -d '"' | xargs)

echo "Using aws account $awsAccountId"

export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
$(aws sts assume-role \
--role-arn arn:aws:iam::${awsAccountId}:role/terraform-dev \
--role-session-name tf-backend-bucket \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--profile runningdinner-$passedStage \
--output text))

aws ssm put-parameter --name "/runningdinner/dockerhub/credentials" \
                      --type "SecureString" \
                      --value "{\"https://index.docker.io/v1/\":{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\"}}" \
                      --overwrite

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

cd "$CUR_DIR_TF" || exit 1