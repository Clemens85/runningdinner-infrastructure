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

resource "aws_key_pair" "runningdinner-sshkey" {
  key_name = "runningdinner-sshkey"
  public_key = file("../../files/id_rsa.pub")
}

resource "aws_iam_instance_profile" "app-instance-role-profile" {
  name = "runningdinner_instance_profile"
  role = data.aws_iam_role.app-instance-role.name
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
echo "ECS_CLUSTER=${aws_ecs_cluster.runningdinner.name}" >> /etc/ecs/ecs.config
echo "ECS_ENGINE_AUTH_TYPE=docker" >> /etc/ecs/ecs.config
echo "ECS_ENGINE_AUTH_DATA={\"https://index.docker.io/v1/\":{\"username\":\"TODO\",\"password\":\"TODO\",\"email\":\"TODO\"}}" >> /etc/ecs/ecs.config
sudo systemctl stop ecs
sudo systemctl start ecs
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

resource "aws_eip" "runningdinner-appserver-ip" {
  instance = aws_instance.runningdinner-appserver.id
  vpc      = true
  tags = local.common_tags
}

#resource "null_resource" "runningdinner-appserver-ip-log" {
#  provisioner "local-exec" {
#    command = "echo ${aws_eip.runningdinner-appserver-ip.address} > .appserver-ip"
#  }
#}