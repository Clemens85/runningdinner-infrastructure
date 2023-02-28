provider "aws" {
  region  = var.region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-${var.stage}"
    session_name = "terraform-app"
  }
}

terraform {
  backend "s3" {
    key = "services/app_v2.tfstate"
  }
}

# See https://github.com/hashicorp/terraform/issues/2283
locals {
  common_tags = tomap({
    "service" = "runningdinner-v2"
    "component" = "app"
  })
}

data "aws_vpc" "runningdinner-vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "runningdinner-app-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.runningdinner-vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.app_subnets_name]
  }
}
data "aws_security_group" "runningdinner-app-traffic" {
  name = "runningdinner-public-traffic"
}

data "aws_iam_role" "app-instance-role" {
  name = var.app_instance_role_name
}

data "aws_ami" "ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = [
      "amzn2-ami-ecs-*"] # ECS optimized image
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "amazon" # Only official images
  ]
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
  cpu                      = 800
  requires_compatibilities = ["EC2"]                                                                                       # Fargate or EC2
  task_role_arn            = data.aws_iam_role.app-instance-role.arn
  tags = local.common_tags
}

data "template_file" "runningdinner-app-task-definition-file" {
  template = file("${path.module}/../../files/runningdinner-task_definition.json")
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
  triggers = {
    redeployment = timestamp()
  }
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "runningdinner-ecs-log-group" {
  name = "runningdinner-backend"
  tags = local.common_tags
}

resource "aws_key_pair" "runningdinner-sshkey" {
  key_name = "runningdinner-sshkey"
  public_key = file("../../files/id_rsa.pub")
}
resource "aws_instance" "runningdinner-appserver" {
  ami = data.aws_ami.ecs.id
  instance_type = var.instance_type
  key_name = aws_key_pair.runningdinner-sshkey.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [data.aws_security_group.runningdinner-app-traffic.id]
  subnet_id = data.aws_subnets.runningdinner-app-subnets.ids[0]
  iam_instance_profile = aws_iam_instance_profile.app-instance-role-profile.name

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.runningdinner.name} >> /etc/ecs/ecs.config
EOF

  lifecycle {
    ignore_changes = [ami, user_data, subnet_id, key_name, ebs_optimized, private_ip]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = var.app_instance_name
    })
  )
}

resource "aws_iam_instance_profile" "app-instance-role-profile" {
  name = "runningdinner_instance_profile"
  role = data.aws_iam_role.app-instance-role.name
}

#resource "aws_eip" "runningdinner-eip" {
#  instance = aws_instance.runningdinner-appserver.id
#  vpc      = true
#  tags = local.common_tags
#}