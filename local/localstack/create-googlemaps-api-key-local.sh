#! /bin/bash

VALUE=$1

# Retrieve param from AWS parameter store if not passed
if [[ -z "$VALUE" ]]; then
  echo "Retrieve param from AWS parameter store"
  SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
  source $SCRIPT_DIR/../../aws/scripts/setup-aws-cli.sh dev
  VALUE=$(aws ssm get-parameter --name "/runningdinner/googlemaps/apikey" --with-decryption --query "Parameter.Value" --output text)
  source $SCRIPT_DIR/../../aws/scripts/clear-aws-cli.sh dev
fi

aws ssm --endpoint-url http://127.0.0.1:4566 put-parameter \
    --name "/runningdinner/googlemaps/apikey" \
    --value "$VALUE" \
    --type "SecureString"