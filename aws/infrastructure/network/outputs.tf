output "sg-app-traffic-id" {
  value = aws_security_group.runningdinner-app-traffic.id
}

output "vpc-id" {
  value = aws_vpc.runningdinner-vpc.id
}

output "role-ec2-instance-arn" {
  value = aws_iam_role.app-instance-role.arn
}