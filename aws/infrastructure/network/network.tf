# See https://github.com/hashicorp/terraform/issues/2283
locals {
  common_tags = tomap({
    "service" = "runningdinner-v2"
    "stage" = var.stage
  })
}

resource "aws_vpc" "runningdinner-vpc" {
  cidr_block = "20.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  assign_generated_ipv6_cidr_block = true
  tags = merge(
    local.common_tags,
    tomap({
      "Name" = var.vpc_name
    })
  )
}

resource "aws_subnet" "runningdinner-app-subnet" {
  count             = length(var.az)
  vpc_id            = aws_vpc.runningdinner-vpc.id
  availability_zone = element(var.az, count.index)
  cidr_block        = "20.0.${count.index + 8}.0/24"
  ipv6_cidr_block = cidrsubnet(aws_vpc.runningdinner-vpc.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "app"
      "Name" = var.app_subnets_name
    })
  )
}

resource "aws_subnet" "runningdinner-db-subnet-a" {
  vpc_id            = aws_vpc.runningdinner-vpc.id
  availability_zone = element(var.az, 0)
  cidr_block        = "20.0.16.0/24"
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "database"
      "Name" = "Runningdinner Database"
    })
  )
}

resource "aws_subnet" "runningdinner-db-subnet-b" {
  vpc_id            = aws_vpc.runningdinner-vpc.id
  availability_zone = element(var.az, 1)
  cidr_block        = "20.0.17.0/24"
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "database"
      "Name" = "Runningdinner Database"
    })
  )
}


resource "aws_route_table" "runningdinner-route-table" {
  vpc_id = aws_vpc.runningdinner-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.runningdinner-internet-gateway.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.runningdinner-internet-gateway.id
  }
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "app"
      "Name" = "Runningdinner App"
    })
  )
}

resource "aws_route_table_association" "runningdinner-route-table-association" {
  count = 3
  subnet_id      = element(aws_subnet.runningdinner-app-subnet.*.id, count.index)
  route_table_id = aws_route_table.runningdinner-route-table.id
}

resource "aws_internet_gateway" "runningdinner-internet-gateway" {
  vpc_id = aws_vpc.runningdinner-vpc.id
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "app"
      "Name" = "Runningdinner App"
    })
  )
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}
resource "aws_security_group" "runningdinner-app-traffic" {
  name        = "runningdinner-public-traffic"
  description = "Allow HTTP(S) traffic from public"
  vpc_id      = aws_vpc.runningdinner-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # TODO: Must probably be in-commented again after first execution...
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   ipv6_cidr_blocks = ["::/0"]
  # }
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "app"
      "Name" = "Internet to App traffic"
    })
  )
}
resource "aws_security_group_rule" "runningdinner-app-traffic-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.runningdinner-app-traffic.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
resource "aws_security_group_rule" "runningdinner-app-traffic-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.runningdinner-app-traffic.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
resource "aws_security_group_rule" "runningdinner-app-traffic-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.runningdinner-app-traffic.id
  cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
}


resource "aws_security_group" "runningdinner-db-app" {
  name        = "runningdinner-db-app"
  description = "Allow traffic from application to database"
  vpc_id      = aws_vpc.runningdinner-vpc.id
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "database"
      "Name" = "App to Database traffic"
    })
  )
}

resource "aws_security_group_rule" "runningdinner-db-app" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  source_security_group_id = aws_security_group.runningdinner-app-traffic.id
  security_group_id = aws_security_group.runningdinner-db-app.id
}

resource "aws_db_subnet_group" "runningdinner-db" {
  name       = "runningdinner-db-subnet-group"
  subnet_ids = [aws_subnet.runningdinner-db-subnet-a.id, aws_subnet.runningdinner-db-subnet-b.id]
  tags = merge(
    local.common_tags,
    tomap({
      "component" = "database"
      "Name" = "Runningdinner Database"
    })
  )
}