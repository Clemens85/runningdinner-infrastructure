

data "aws_ssm_parameter" "geocode-participant-sqs-arn" {
  name = "/runningdinner/geocode-participant/sqs/arn"
}

data "aws_ssm_parameter" "database-url" {
  name = "/runningdinner/database/url"
}

data "aws_ssm_parameter" "database-username-admin" {
  name = "/runningdinner/database/username/admin"
}

data "aws_ssm_parameter" "database-password-admin" {
  name = "/runningdinner/database/password/admin"
}

resource "random_password" "database-password-app" {
  length           = 16
  special          = false
}

resource "aws_ssm_parameter" "database-password-app" {
  type = "SecureString"
  name = "/runningdinner/database/password/app"
  tags = local.common_tags
  value = random_password.database-password-app.result
}

resource "aws_ssm_parameter" "database-username-app" {
  type = "SecureString"
  name = "/runningdinner/database/username/app"
  tags = local.common_tags
  value = "runningdinner"
}

resource "aws_ecs_cluster" "runningdinner" {
  name = "runningdinner-ecs-cluster"
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "runningdinner" {
  container_definitions    = data.template_file.runningdinner-app-task-definition-file.rendered
  execution_role_arn       = data.aws_iam_role.app-instance-role.arn
  family                   = "runningdinner-backend"
  network_mode             = "host"                                                                                      # network mode awsvpc, brigde
  memory                   = "300"
  cpu                      = 800 # 0.8 CPU units
  requires_compatibilities = ["EC2"]# Fargate or EC2
  volume {
    name = "app-logs"
    host_path = "/logs"
  }
  task_role_arn            = data.aws_iam_role.app-instance-role.arn
  tags = local.common_tags
  depends_on = [ aws_instance.runningdinner-appserver ]
}

data "template_file" "runningdinner-app-task-definition-file" {
  template = file("${path.module}/../../files/runningdinner-task_definition.json")
  vars = {
    SPRING_DATASOURCE_URL_SSM_ARN = data.aws_ssm_parameter.database-url.arn
    SPRING_FLYWAY_USER_SSM_ARN = data.aws_ssm_parameter.database-username-admin.arn
    SPRING_FLYWAY_PASSWORD_SSM_ARN = data.aws_ssm_parameter.database-password-admin.arn
    SPRING_DATASOURCE_USERNAME_SSM_ARN = aws_ssm_parameter.database-username-app.arn
    SPRING_DATASOURCE_PASSWORD_SSM_ARN = aws_ssm_parameter.database-password-app.arn
    AWS_SQS_GEOCODE_URL_SSM_ARN = data.aws_ssm_parameter.geocode-participant-sqs-arn.arn
    IMAGE_TAG_VERSION = "latest"
    AWS_REGION = var.region
    AWS_ACCOUNT_ID = var.aws_account_id
  }
}

resource "aws_ecs_service" "runningdinner-ecs-service" {
  name            = "runningdinner-service"
  cluster         = aws_ecs_cluster.runningdinner.id
  task_definition = aws_ecs_task_definition.runningdinner.arn
  launch_type     = "EC2"
  desired_count   = 1
  deployment_minimum_healthy_percent = 0
  #  network_configuration {
  #    security_groups       = [data.aws_security_group.runningdinner-app-traffic.id]
  #    subnets               = [data.aws_subnets.runningdinner-app-subnets.ids[0]]
  #    assign_public_ip      = "false"
  #  }
  force_new_deployment = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  triggers = {
    redeployment = timestamp()
  }
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "runningdinner-ecs-log-group" {
  name = "runningdinner-backend"
  tags = local.common_tags
  retention_in_days = 7
}
