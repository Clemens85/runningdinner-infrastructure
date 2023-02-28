output "rds-address" {
  value = aws_db_instance.runningdinner-db.address
}

output "rds-name" {
  value = aws_db_instance.runningdinner-db.db_name
}