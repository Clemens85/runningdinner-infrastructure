provider "aws" {
  region  = var.region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-${var.stage}"
    session_name = "terraform-database"
  }
}

terraform {
  backend "s3" {
    key = "services/db-v2.tfstate"
  }
}

# See https://github.com/hashicorp/terraform/issues/2283
locals {
  common_tags = tomap({
    "service" = "runningdinner-v2"
    "component" = "database"
  })
}

data "aws_security_group" "runningdinner-db-app" {
  name = "runningdinner-db-app"
}

data "aws_db_subnet_group" "runningdinner-db-subnet" {
  name = "runningdinner-db-subnet-group"
}

resource "random_password" "runningdinner-db-password" {
  length           = 16
  special          = false
}

resource "aws_ssm_parameter" "runningdinner-db-password" {
  type = "SecureString"
  name = "/runningdinner/database/password"
  tags = local.common_tags
  value = random_password.runningdinner-db-password.result
}

resource "aws_db_instance" "runningdinner-db" {
  identifier             = "runningdinner"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.4"
  username               = "runningdinner"
  password               = random_password.runningdinner-db-password.result
  db_subnet_group_name   = data.aws_db_subnet_group.runningdinner-db-subnet.name
  vpc_security_group_ids = [data.aws_security_group.runningdinner-db-app.id]
  skip_final_snapshot    = true
  tags = local.common_tags
}




#data "aws_subnets" "runningdinner-app-subnets" {
#  filter {
#    name   = "vpc-id"
#    values = [data.aws_vpcs.runningdinner-vpc[0].id]
#  }
#  tags = {
#    "component" = "database"
#  }
#}

#data "aws_vpcs" "runningdinner-vpc" {
#  tags = {
#    "service" = "runningdinner-v2"
#  }
#}



#resource "aws_security_group" "runningdinner-db-app" {
#  name        = "runningdinner-db-app"
#  description = "Allow traffic from application to database"
#  vpc_id      = data.aws_vpcs.runningdinner-vpc[0].id
#  tags = local.common_tags
#}
#
#resource "aws_security_group_rule" "runningdinner-db-app" {
#  type              = "ingress"
#  from_port         = 5432
#  to_port           = 5432
#  protocol          = "tcp"
#  source_security_group_id = data.aws_security_group.runningdinner-app-traffic.id
#  security_group_id = aws_security_group.runningdinner-db-app.id
#}
#
#resource "aws_db_subnet_group" "runningdinner-db" {
#  name       = "runningdinner-db-subnet"
#  subnet_ids = [data.aws_subnets.runningdinner-app-subnets[0].id, data.aws_subnets.runningdinner-app-subnets[1].id]
#  tags = local.common_tags
#}