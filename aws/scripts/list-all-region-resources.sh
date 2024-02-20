#! /bin/bash

CUR_DIR_TF=$(pwd)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source setup-aws-cli.sh

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing instances in region $region"
    aws ec2 describe-instances --region $region
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing ECS clusters in region $region"
    aws ecs list-clusters --region $region
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing Lambda functions in region $region"
    aws lambda list-functions --region $region
done

for cluster_arn in $(aws ecs list-clusters --query 'clusterArns' --output text); do
    echo "Listing tasks for ECS cluster $cluster_arn"
    aws ecs list-tasks --cluster $cluster_arn
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing RDS instances in region $region"
    aws rds describe-db-instances --region $region
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing Elastic Beanstalk environments in region $region"
    aws elasticbeanstalk describe-environments --region $region
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing NAT Gateways in region $region"
    aws ec2 describe-nat-gateways --region $region
done

for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
    echo "Listing ECR repositories in region $region"
    aws ecr describe-repositories --region $region
done

source clear-aws-cli.sh

cd $CUR_DIR_TF