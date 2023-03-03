output "ec2-public-ip" {
  value = aws_instance.runningdinner-appserver.public_ip
}

output "ec2-public-dns" {
  value = aws_instance.runningdinner-appserver.public_dns
}

output "elastic-ip" {
  value = aws_eip.runningdinner-appserver-ip.public_ip
}

output "ami-name" {
  value = data.aws_ami.ecs.name
}

output "ami-id" {
  value = data.aws_ami.ecs.id
}