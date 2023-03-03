#! /bin/bash

CUR_DIR=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

read -r DNS < ../infrastructure/app/.appserver-ip.txt
echo "Using $DNS"

cd $CUR_DIR

ssh ec2-user@"$DNS"