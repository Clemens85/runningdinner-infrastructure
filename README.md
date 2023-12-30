# Initial Setup for AWS (Prerequisites)

## AWS Accounts
* AWS root account with organizations setup
* Child account for dev stage
* Child account for prod stage

## Users and Roles

For each stage:

IAM user (e.g. `runningdinner-dev`) in root account with role-assume policy for child account.
Example policy (inline): 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::CHILD_ACCOUNT_ID:role/terraform-dev"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "*"
        }
    ]
}
```
---

Child account must have a role named `terraform-dev` that is allowed to be assumed by IAM user in root account.
Example policy of trust relationship:
```json 
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::CHILD_ACCOUNT_ID:user/runningdinner-dev",
                    "arn:aws:iam::CHILD_ACCOUNT_ID:root"
                ]
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```

This role must further also have the appropriate access policies assigned, e.g. `AdministratorAccess`.<br/> 
(The name "terraform-dev" is unfortunate due to it is the same for all stages)

See also https://medium.com/@aw.panda.aws/4-steps-to-deploy-to-multiple-aws-accounts-with-terraform-bbb00bb4e789

## S3 Buckets (Terraform backends)

In each child account (stage) a S3 bucket must be created for the Terraform backend.
It must match the configuration in `./aws/config/config.sh`

## Local AWS credentials

The ~/.aws/credentials must contain both a profile runningdinner-dev and runningdinner-prod whith tokens
matching the appropriate IAM users created above.

## Parameter Store Entries

Following Parameter Store entries must exist (as secrets) in each account:

* /runningdinner/dockerhub/credentials
* /runningdinner/logzio/token
* /runningdinner/googlemaps/apikey
* /runningdinner/paypal/baseurl
* /runningdinner/paypal/clientid
* /runningdinner/paypal/secret

Use `./aws/scripts/create-ssm-paraemter.sh` respectively `./aws/scripts/create-dockerhub-credentials.sh` scripts.  

## Manual Deployment of App

If CircleCI not available:

* Backend: `./aws/scripts/deploy-ecs-task.sh <STAGE>` (deploys latest tag)
* Frontend: `./aws/scripts/deploy-s3-content.sh <STAGE> runningdinner-web-<STAGE>`
