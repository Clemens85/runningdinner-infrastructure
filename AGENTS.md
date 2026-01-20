# RunningDinner Infrastructure - AI Coding Instructions

## Architecture Overview

Multi-account AWS infrastructure for "runningdinner" app, managed with Terraform across dev/prod stages. Uses cross-account role assumption pattern with child AWS accounts.

**Module deployment order** (dependencies exist): network → database → app → dns → mail

Each module has independent Terraform state in S3 backend, organized under `aws/infrastructure/{network,database,app,dns,mail}/`.

## Critical Workflows

### Terraform Operations (Use tf.sh wrapper)

**Always use the wrapper script** - never run `terraform` directly:

```bash
# Pattern: ./aws/infrastructure/tf.sh <STAGE> <MODULE> <COMMAND>
./aws/infrastructure/tf.sh dev network init    # Initialize with remote backend
./aws/infrastructure/tf.sh dev network plan
./aws/infrastructure/tf.sh dev network apply
```

The wrapper (`aws/infrastructure/tf.sh`) handles:

- Cross-account role assumption via `TF_VAR_assume_role_arn`
- Remote S3 backend configuration per stage
- Stage-specific tfvars from `aws/config/stages/{dev,prod}/`
- Context tracking in `.tfcontext` file (prevents accidental stage switching)

### Stage Configuration

Stage configs in `aws/config/stages/{common.tfvars,dev/default.tfvars,prod/default.tfvars}`. Common tfvars apply to all stages.

### Local Development

Start full local stack (Postgres, Localstack SQS/SSM):

```bash
./local/start-dev-env.sh  # Creates docker network, sets up SQS and mock SSM parameters
./local/stop-dev-env.sh
```

### Manual Deployments (when CircleCI unavailable)

```bash
./aws/scripts/deploy-ecs-task.sh <STAGE>           # Backend to ECS
./aws/scripts/deploy-s3-content.sh <STAGE> <BUCKET> # Frontend to S3
```

## IAM & Cross-Account Pattern

**Root account** has IAM users (e.g., `runningdinner-dev`) that assume roles in child accounts.

**Child accounts** have `terraform-{stage}` roles (confusingly named same across stages) with AdministratorAccess.

When editing IAM policies in `aws/infrastructure/network/iam.tf`:

- `app-instance-role`: Used by EC2/ECS tasks for runtime permissions (SSM, SQS, S3, logs)
- `ci-user-policy`: For CI/CD deployments - needs CloudFormation, Lambda, S3, DynamoDB, SNS, SQS

Variables `${var.aws_account_id}` and `${var.region}` are injected by tf.sh from stage tfvars.

## Required SSM Parameters (per stage)

Must exist before deployment:

```
/runningdinner/dockerhub/credentials
/runningdinner/logzio/token
/runningdinner/googlemaps/apikey
/runningdinner/paypal/{baseurl,clientid,secret}
```

Create with `./aws/scripts/create-ssm-parameter.sh` or `./aws/scripts/create-dockerhub-credentials.sh`

## Project Conventions

- **Never hardcode AWS account IDs** - always use `${var.aws_account_id}` variable
- **Module isolation**: Each infrastructure module is independent with its own backend
- **Script location matters**: Scripts assume execution from their own directory (use `cd "$( dirname "${BASH_SOURCE[0]}" )"`)
- **Stage-first**: Stage is always first parameter in scripts (dev/prod)
- **Docker CLI**: Use `./cli.sh` for interactive Terraform container (mounts .aws credentials)

## Key Files

- [aws/config/config.sh](aws/config/config.sh) - Stage validation and environment setup
- [aws/infrastructure/tf.sh](aws/infrastructure/tf.sh) - **Always use this for Terraform**
- [aws/infrastructure/network/iam.tf](aws/infrastructure/network/iam.tf) - IAM roles and policies
- [README.md](README.md) - AWS account setup prerequisites
