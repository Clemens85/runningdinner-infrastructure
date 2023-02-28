#! /bin/bash

export TF_VAR_region="eu-central-1"
export DNS_EMAIL="runyourdinner@gmail.com"

setupValidEnvironmentVars () {
  passedStage=$1
  if [[ -z "$passedStage" ]]; then
    echo "Error: Must pass a stage as first parameter"
    exit 1
  fi
  configDir=$(dirname "${BASH_SOURCE[0]}")
  if [[ ! -d "${configDir}/stages/${passedStage}" ]]; then
      echo "The stage '${passedStage}' doesn't exist under config/stages"
      echo "These stages are available:"
      ls "${configDir}/stages/"
      exit 1
  fi

  awsAccountId=$(grep aws_account_id "${configDir}/stages/${passedStage}/default.tfvars" | awk -F= '{print $2}' | tr -d '"' | xargs)
  export TF_VAR_aws_account_id="$awsAccountId"
  export TF_VAR_assume_role_arn="arn:aws:iam::$TF_VAR_aws_account_id:role/terraform-$STAGE"
  export TF_BACKEND_BUCKET="runningdinner-tf-backend-$STAGE"
}

#createBackendBucket() {
#  passedStage=$1
#  awsAccountId=$2
#
#  #aws sts assume-role --role-arn "arn:aws:iam::$awsAccountId:role/terraform-dev" --role-session-name test --profile runningdinner-$STAGE
#
#  export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
#  $(aws sts assume-role \
#  --role-arn arn:aws:iam::$awsAccountId:role/terraform-dev \
#  --role-session-name tf-backend-bucket \
#  --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
#  --profile runningdinner-$passedStage \
#  --output text))
#
#  assumedAccountId=$(aws sts get-caller-identity --output text | awk '{print $1}')
#  if [[ "$assumedAccountId" != "$awsAccountId" ]]; then
#      echo "Expected to assume $awsAccountId, but was $assumedAccountId"
#      exit 1
#  fi
#}
