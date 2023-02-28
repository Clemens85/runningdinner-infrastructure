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

resource "random_password" "runningdinner-db-password-admin" {
  length           = 16
  special          = false
}

resource "aws_ssm_parameter" "runningdinner-db-password-admin" {
  type = "SecureString"
  name = "/runningdinner/database/password/admin"
  tags = local.common_tags
  value = random_password.runningdinner-db-password-admin.result
}

resource "aws_ssm_parameter" "runningdinner-db-username-admin" {
  type = "SecureString"
  name = "/runningdinner/database/username/admin"
  tags = local.common_tags
  value = "runningdinner_admin"
}

resource "aws_db_instance" "runningdinner-db" {
  identifier             = "runningdinner"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.4"
  username               = aws_ssm_parameter.runningdinner-db-username-admin.value
  password               = random_password.runningdinner-db-password-admin.result
  db_subnet_group_name   = data.aws_db_subnet_group.runningdinner-db-subnet.name
  vpc_security_group_ids = [data.aws_security_group.runningdinner-db-app.id]
  skip_final_snapshot    = true
  tags = local.common_tags
  db_name = "runningdinner"
  delete_automated_backups = true
}

resource "aws_ssm_parameter" "runningdinner-db-url" {
  type = "String"
  name = "/runningdinner/database/url"
  tags = local.common_tags
  value = "jdbc:postgresql://${aws_db_instance.runningdinner-db.address}:5432/runningdinner"
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