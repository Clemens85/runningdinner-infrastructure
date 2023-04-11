#! /bin/bash

#env -i bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

BUCKET_NAME=$2
if [[ -z "$BUCKET_NAME" ]]; then
  echo "Error: Must pass the bucket name for which to sync the webapp files as second param"
  exit 1
fi

CONTENT_BUILD_DIR="../../../runningdinner/runningdinner-client/packages/webapp/build"

if [ ! -d "$CONTENT_BUILD_DIR" ] || [ ! "$(ls -A $CONTENT_BUILD_DIR)" ]; then
  echo "$CONTENT_BUILD_DIR does either not exist or has no files inside"
  exit 1
fi

aws s3 sync "$CONTENT_BUILD_DIR/" "s3://$BUCKET_NAME" --delete

source clear-aws-cli.sh

cd $CUR_DIR_TF