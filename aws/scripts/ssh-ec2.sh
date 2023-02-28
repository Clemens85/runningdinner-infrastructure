#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

STAGE=$1

../infrastructure/tf.sh $STAGE app init
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

cd ../infrastructure/app
dns=$(terraform output ec2-public-dns)
dns=$(echo "${dns//\"}")

echo "Connecting to $dns"
ssh ec2-user@$dns