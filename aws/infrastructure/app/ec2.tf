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
      # "amzn2-ami-ecs-*" # Old ECS optimized Amazon Linux 2 image
      "al2023-ami-ecs-*" # ECS optimized Amazon Linux 2023 image
    ]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  filter {
    name = "architecture"  # Add this filter to specify desired architecture
    values = [
      # "x86_64"
      "arm64"
      ]
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
set -e  # Exit on error
exec > >(tee /var/log/user-data.log) 2>&1  # Log user-data output

#sudo yum -y update
sudo yum -y update --security
# *** ECS Config *** #
echo "ECS_CLUSTER=${aws_ecs_cluster.runningdinner.name}" >> /etc/ecs/ecs.config
echo "ECS_ENGINE_AUTH_TYPE=docker" >> /etc/ecs/ecs.config
DOCKERHUB_CREDS='${data.aws_ssm_parameter.dockerhub-credentials.value}'
echo "ECS_ENGINE_AUTH_DATA=$DOCKERHUB_CREDS" >> /etc/ecs/ecs.config
sudo systemctl restart docker
sudo yum -y install nano

# *** Logz.io Config ***
sudo curl https://raw.githubusercontent.com/logzio/public-certificates/master/AAACertificateServices.crt --create-dirs -o /etc/pki/tls/certs/COMODORSADomainValidationSecureServerCA.crt

# Install filebeat for ARM64 architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  # For ARM64, download and install filebeat directly from Elastic
  FILEBEAT_VERSION="8.17.0"
  sudo curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$${FILEBEAT_VERSION}-linux-arm64.tar.gz
  sudo tar xzvf filebeat-$${FILEBEAT_VERSION}-linux-arm64.tar.gz -C /opt
  sudo mv /opt/filebeat-$${FILEBEAT_VERSION}-linux-arm64 /opt/filebeat
  sudo rm filebeat-$${FILEBEAT_VERSION}-linux-arm64.tar.gz
  
  # Create directories first
  sudo mkdir -p /etc/filebeat /var/lib/filebeat /var/log/filebeat
  
  # Make filebeat executable
  sudo chmod +x /opt/filebeat/filebeat
  
  # Create systemd service for filebeat
  sudo tee /etc/systemd/system/filebeat.service > /dev/null <<EOL
[Unit]
Description=Filebeat sends log files to Logstash or directly to Elasticsearch.
Documentation=https://www.elastic.co/beats/filebeat
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/filebeat/filebeat -e -c /etc/filebeat/filebeat.yml --path.home /opt/filebeat --path.config /etc/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL
  
else
  # For x86_64, use the standard yum installation
  sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
  echo '${data.local_file.filebeat-yum-repo.content}' | sudo tee /etc/yum.repos.d/elastic.repo > /dev/null
  sudo yum -y install filebeat
fi

# Configure and start filebeat
echo '${data.template_file.filebeat.rendered}' | sudo tee /etc/filebeat/filebeat.yml > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable filebeat
sudo systemctl start filebeat

EOF

  lifecycle {
    ignore_changes = [user_data, subnet_id, key_name, ebs_optimized, private_ip]
  }

  depends_on = [ aws_ecs_cluster.runningdinner ]

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