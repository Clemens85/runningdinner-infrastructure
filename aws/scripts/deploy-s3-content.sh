#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

BUCKET_NAME=$2
if [[ -z "$BUCKET_NAME" ]]; then
  echo "Error: Must pass the bucket name for which to sync the webapp files as second param"
  exit 1
fi

GOOGLE_MAPS_KEY=$(aws ssm get-parameter --name "/runningdinner/googlemaps/apikey" --with-decryption --query "Parameter.Value" --output text)
export REACT_APP_GOOGLE_MAPS_KEY_JS="$GOOGLE_MAPS_KEY"
echo "Gotten key = $REACT_APP_GOOGLE_MAPS_KEY_JS"

CLIENT_DIR="../../../runningdinner/runningdinner-client/webapp"

echo "Building runningdinner-client"
SCRIPT_DIR=$(pwd)
cd $CLIENT_DIR && pnpm build
cd $SCRIPT_DIR

CONTENT_BUILD_DIR="$CLIENT_DIR/dist"
if [ ! -d "$CONTENT_BUILD_DIR" ] || [ ! "$(ls -A $CONTENT_BUILD_DIR)" ]; then
  echo "$CONTENT_BUILD_DIR does either not exist or has no files inside"
  exit 1
fi

echo "Deploying to $BUCKET_NAME"
aws s3 sync "$CONTENT_BUILD_DIR/" "s3://$BUCKET_NAME" --delete

source clear-aws-cli.sh

cd $CUR_DIR_TF