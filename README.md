# Initial Setup for AWS (Prerequisites)

## AWS Accounts
* AWS root account with organizations setup
* Child account for dev stage
* Child account for prod stage

## Users and Roles

For each stage:

IAM user in root account with role-assume policy for child account.
Example policy: 

```d ```

Child account must have role with Admin-Access policy that is allowed to be assumed by IAM user in root account.
Example policy:
```json 
TODO
```

See also https://medium.com/@aw.panda.aws/4-steps-to-deploy-to-multiple-aws-accounts-with-terraform-bbb00bb4e789

## S3 Buckets (Terraform backends)

In each child account (stage) a S3 bucket must be created for the Terraform backend.
It must match the configuration in `./aws/config/config.sh`

## Local AWS credentials

The ~/.aws/credentials must contain both a profile runningdinner-dev and runningdinner-prod whith tokens
matching the appropriate IAM users created above.


