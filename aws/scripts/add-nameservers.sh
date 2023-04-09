#! /bin/bash

set +e

# Reference https://theburningmonk.com/2021/05/how-to-manage-route53-hosted-zones-in-a-multi-account-environment/ for more information

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

currentExecutionStage=$2
if [[ $currentExecutionStage == "prod" ]]; then
  echo "Nothing needs to be done for prod stage"
  source clear-aws-cli.sh
  cd $CUR_DIR_TF
  exit 0
fi

HOSTED_ZONE_ID="ZX9JVHNHZRJLS" # This was already manually created in past

# Iterate through remaining args (starting only with third command arg, first two args are stage which to assume and the stage we are currently executing):
# Example result: NAMESERVERS={ "Value": "ns1.example.com." }, { "Value": "ns2.example.com." }, { "Value": "ns3.example.com." }
NAMESERVERS=""
shift 2
for NS in "$@"
do
  NAMESERVERS="$NAMESERVERS{\"Value\": \"$NS.\"},"
done
NAMESERVERS="${NAMESERVERS/%,/''}"

if [[ $NAMESERVERS == "" ]]; then
  echo "No single Nameserver was passed!"
  exit 1
fi

echo "Got $NAMESERVERS"
RECORD_NAME="$currentExecutionStage.runyourdinner.eu."
RECORD_TYPE="NS"

# Check if the record already exists in the hosted zone
EXISTING_RECORD=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --query "ResourceRecordSets[?Name == '${RECORD_NAME}' && Type == '${RECORD_TYPE}']" \
  --output text)

echo "Got existing record $EXISTING_RECORD"

ACTION="UPSERT"
if [[ -z "${EXISTING_RECORD}" ]]; then
  ACTION="CREATE"
fi

echo "Using action $ACTION"

CHANGE_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --change-batch "{\"Changes\":[{\"Action\":\"${ACTION}\",\"ResourceRecordSet\":{\"Name\":\"${RECORD_NAME}\",\"Type\":\"${RECORD_TYPE}\",\"TTL\":300,\"ResourceRecords\":[ ${NAMESERVERS} ] }}]}" \
  --query "ChangeInfo.Id" \
  --output text )

# Wait until the Route53 change is complete
echo "Waiting for Route53 change to complete with CHANGE_ID $CHANGE_ID ..."
aws route53 wait resource-record-sets-changed --id "${CHANGE_ID}"

echo "Route53 change completed."

source clear-aws-cli.sh

cd $CUR_DIR_TF