#!/bin/bash
# see https://blog.cloudinvaders.com/add-your-ip-address-to-an-ec2-security-group-from-command-line/
export IP=`curl -s https://api.ipify.org`
echo $IP

SECURITY_GROUP_ID="TODO"

aws ec2 authorize-security-group-ingress --protocol tcp --port 22 --cidr $IP/32 --group-id $SECURITY_GROUP_ID