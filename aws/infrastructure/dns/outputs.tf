

output "cloudfront-id" {
  value = aws_cloudfront_distribution.runningdinner.id
}

output "cloudfront-url" {
  value = aws_cloudfront_distribution.runningdinner.domain_name
}

output "name_servers" {
  value = aws_route53_zone.runningdinner.name_servers
}