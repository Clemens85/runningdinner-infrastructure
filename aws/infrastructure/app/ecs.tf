resource "aws_ssm_parameter" "host-context-url" {
  type = "String"
  name = "/runningdinner/host/context/url"
  tags = local.common_tags
  value = "https://${var.domain_name}"
}

resource "aws_ecs_cluster" "runningdinner" {
  name = "runningdinner-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "runningdinner" {
  container_definitions    = data.template_file.runningdinner-app-task-definition-file.rendered
  execution_role_arn       = data.aws_iam_role.app-instance-role.arn
  family                   = "runningdinner-backend"
  network_mode             = "host"                                                                                      # network mode awsvpc, brigde
  # memory                   = "300"
  # cpu                      = 1000 # 0.8 CPU units
  # cpu = 1536
  requires_compatibilities = ["EC2"]# Fargate or EC2
  volume {
    name = "app-logs"
    host_path = "/logs"
  }
  volume {
    name = "varlibdocker"
    host_path = "/var/lib/docker"
  }
  volume {
    name = "varrundocker"
    host_path = "/var/run/docker.sock"
  }
  task_role_arn            = data.aws_iam_role.app-instance-role.arn
  tags = local.common_tags
  depends_on = [ aws_instance.runningdinner-appserver, aws_ssm_parameter.host-context-url ]

  # Uncomment this for not updating ECS service
#  lifecycle {
#    ignore_changes = [ container_definitions ]
#  }
}

data "template_file" "runningdinner-app-task-definition-file" {
  template = file("${path.module}/../../files/runningdinner-task-definition.json")
  vars = {
    IMAGE_TAG_VERSION = "latest"
    AWS_REGION = var.region
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

  force_new_deployment = var.force_backend_deployment

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Uncomment this for don't updating ECS service
#  lifecycle {
#    ignore_changes = [ task_definition ]
#  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "runningdinner-ecs-log-group" {
  name = "runningdinner-backend"
  tags = local.common_tags
  retention_in_days = 7
}

resource "aws_cloudwatch_query_definition" "runningdinner-ecs-log-query" {
  name = "runningdinner-backend desc"

  log_group_names = [
    aws_cloudwatch_log_group.runningdinner-ecs-log-group.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| sort @timestamp desc
| limit 250
EOF
}