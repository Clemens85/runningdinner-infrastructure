#! /bin/bash

passedStage=$1
if [[ -z "$passedStage" ]]; then
  echo "Error: Must pass a stage as first parameter"
  exit 1
fi

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

