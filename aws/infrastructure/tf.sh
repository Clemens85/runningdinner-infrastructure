#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

TF_CONTEXT_DIR="${CUR_DIR_TF}"

writeCurrentTerraformContext() {
  passedStage=$1
  passedConfigDir=$2
  tfContextFile="$TF_CONTEXT_DIR/.tfcontext"
  echo "$passedStage" > $tfContextFile
  echo "$passedConfigDir" >> $tfContextFile
}

printCurrentTerraformContext() {
  tfContextFile="$TF_CONTEXT_DIR/.tfcontext"
  if [[ -d "$tfContextFile" ]]; then
    echo "*** No TF context used before ***"
  else
    echo "*** Using current TF Context"
    head -n 2 $tfContextFile
    echo "***"
  fi
}


source ../config/config.sh
STAGE=$1

setupValidEnvironmentVars "$STAGE"

TF_CONFIG_DIR=$2
if [[ ! -d "./${TF_CONFIG_DIR}" ]]; then
    echo "The config '${TF_CONFIG_DIR}' doesn't exist"
    echo "These config folders are available:"
    ls .
    exit 1
fi
cd "$TF_CONFIG_DIR" || exit 1

TF_COMMAND=$3

subCommandsWithVars=(apply destroy plan)
subCommandsWithBackend=(init)
subCommandsWithoutVars=(output)

# shellcheck disable=SC2199
if [[ " ${subCommandsWithVars[@]} " =~ ${TF_COMMAND} ]]; then
  printCurrentTerraformContext
  # shellcheck disable=SC2145
  TF_VAR_FILE_CONFIG="-var-file=../../config/stages/common.tfvars -var-file=../../config/stages/${STAGE}/default.tfvars"
  # shellcheck disable=SC2145
  echo "Running in $(pwd): terraform $TF_COMMAND $TF_VAR_FILE_CONFIG ${@:4}"
  terraform "$TF_COMMAND" $TF_VAR_FILE_CONFIG "${@:4}"
elif [[ " ${subCommandsWithoutVars[@]} " =~ ${TF_COMMAND} ]]; then
  printCurrentTerraformContext
  # shellcheck disable=SC2145
  terraform "$TF_COMMAND" "${@:4}"
elif [[ " ${subCommandsWithBackend[@]} " =~ ${TF_COMMAND} ]]; then
  # shellcheck disable=SC2145
  echo "Running in $(pwd): terraform init ${@:4} with remote backend in $TF_BACKEND_BUCKET for stage $STAGE"
  terraform init \
           -reconfigure \
           -backend-config="bucket=$TF_BACKEND_BUCKET" \
           -backend-config="region=$TF_VAR_region" \
           -backend-config="role_arn=$TF_VAR_assume_role_arn"
           "${@:4}"
  writeCurrentTerraformContext "$STAGE" "$TF_CONFIG_DIR"
else
  echo "Unknown terraform command $TF_COMMAND"
  exit 1
fi

cd "$CUR_DIR_TF" || exit 1