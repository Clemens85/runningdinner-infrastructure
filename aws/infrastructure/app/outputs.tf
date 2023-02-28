output "ec2-public-ip" {
  value = aws_instance.runningdinner-appserver.public_ip
}

output "ec2-public-dns" {
  value = aws_instance.runningdinner-appserver.public_dns
}

output "ec2-instance-id" {
  value = aws_instance.runningdinner-appserver.id
}