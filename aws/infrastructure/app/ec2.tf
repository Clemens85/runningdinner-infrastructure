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

  filter {
    name = "architecture"  # Add this filter to specify x86_64 architecture
    values = [
      "x86_64"]
  }

  owners = [
    "amazon" # Only official images
  ]
}

data "aws_ssm_parameter" "dockerhub-credentials" {
  name = "/runningdinner/dockerhub/credentials"
}

resource "aws_key_pair" "runningdinner-sshkey" {
  key_name = "runningdinner-sshkey"
  public_key = file("../../files/id_rsa.pub")
}

resource "aws_iam_instance_profile" "app-instance-role-profile" {
  name = "runningdinner_instance_profile"
  role = data.aws_iam_role.app-instance-role.name
}

data "aws_ssm_parameter" "logzio-token" {
  name = "/runningdinner/logzio/token"
}

data "template_file" "filebeat" {
  template = file("${path.module}/../../files/filebeat.yml")
  vars = {
    LOGZ_IO_TOKEN = data.aws_ssm_parameter.logzio-token.value
  }
}

data "local_file" "filebeat-yum-repo" {
  filename = "${path.module}/../../files/elastic.repo"
}

resource "aws_instance" "runningdinner-appserver" {
  ami = data.aws_ami.ecs.id
  instance_type = var.instance_type
  key_name = aws_key_pair.runningdinner-sshkey.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [data.aws_security_group.runningdinner-app-traffic.id]
  subnet_id = data.aws_subnets.runningdinner-app-subnets.ids[0]
  iam_instance_profile = aws_iam_instance_profile.app-instance-role-profile.name
  ipv6_address_count = 1

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Switch EBS volume to gp3 instaed of gp2 (which is a little cheaper)...
  # Default size of 30 Gib can unfortunately not be adapted due to AMI restrictions
  root_block_device {
    volume_type = "gp3"
  }

  user_data = <<EOF
#!/bin/bash
# *** ECS Config *** #
echo "ECS_CLUSTER=${aws_ecs_cluster.runningdinner.name}" >> /etc/ecs/ecs.config
echo "ECS_ENGINE_AUTH_TYPE=docker" >> /etc/ecs/ecs.config
DOCKERHUB_CREDS='${data.aws_ssm_parameter.dockerhub-credentials.value}'
echo "ECS_ENGINE_AUTH_DATA=$DOCKERHUB_CREDS" >> /etc/ecs/ecs.config
sudo systemctl restart docker
sudo yum -y install nano

# *** Logz.io Config ***
sudo curl https://raw.githubusercontent.com/logzio/public-certificates/master/AAACertificateServices.crt --create-dirs -o /etc/pki/tls/certs/COMODORSADomainValidationSecureServerCA.crt
sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
sudo echo '${data.local_file.filebeat-yum-repo.content}' > /etc/yum.repos.d/elastic.repo
sudo yum -y install filebeat
sudo systemctl enable filebeat
sudo echo '${data.template_file.filebeat.rendered}' > /etc/filebeat/filebeat.yml
sudo systemctl start filebeat

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
resource "null_resource" "runningdinner-appserver-ip-log" {
  triggers = {
    value = aws_instance.runningdinner-appserver.public_dns
  }
  depends_on = [aws_instance.runningdinner-appserver]
  provisioner "local-exec" {
    command = <<EOF
      echo ${aws_instance.runningdinner-appserver.public_dns} > .appserver-ip-${var.stage}.txt
    EOF
  }
}