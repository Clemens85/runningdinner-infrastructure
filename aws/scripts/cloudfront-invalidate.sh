#! /bin/bash

#env -i bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

distributions=$(aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id}' --output text)
# Check if there is only one distribution
if [ $(echo "$distributions" | wc -l) -ne 1 ]; then
  echo "Error: There are either no CloudFront distributions or multiple distributions in the account." >&2
  cd $CUR_DIR_TF
  exit 1
fi

# Get the distribution ID
distribution_id=$(echo "$distributions" | awk '{print $1}')

echo "Invalidating $distribution_id"
aws cloudfront create-invalidation --distribution-id $distribution_id --paths "/*"

source clear-aws-cli.sh

cd $CUR_DIR_TF