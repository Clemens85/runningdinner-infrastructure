#! /bin/bash

set +e

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

currentExecutionStage=$2
if [[ $currentExecutionStage == "prod" ]]; then
  echo "Nothing needs to be done for prod stage"
  cd $CUR_DIR_TF
  exit 0
fi

HOSTED_ZONE_ID="ZX9JVHNHZRJLS" # This was already manually created in past

# Iterate through remaining args (starting only with third command arg, first two args are stage which to assume and the stage we are currently executing):
# NAMESERVERS='['
# # Example: NAMESERVERS='["ns1.example.com.", "ns2.example.com.", "ns3.example.com."]'
# shift 2
# for NS in "$@"
# do
#   NAMESERVERS="$NAMESERVERS'$NS.',"
# done
# NAMESERVERS="${NAMESERVERS/%,/''}"
# NAMESERVERS="$NAMESERVERS]"


NAMESERVERS=""
# Example: NAMESERVERS={ "Value": "ns1.example.com." }, { "Value": "ns2.example.com." }, { "Value": "ns3.example.com." }
shift 2
for NS in "$@"
do
  NAMESERVERS="$NAMESERVERS{\"Value\": \"$NS.\"}," 
done
NAMESERVERS="${NAMESERVERS/%,/''}"

echo "Result = $NAMESERVERS"
