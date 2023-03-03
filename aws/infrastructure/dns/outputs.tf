

output "cloudfront-id" {
  value = aws_cloudfront_distribution.runningdinner.id
}

output "cloudfront-url" {
  value = aws_cloudfront_distribution.runningdinner.domain_name
}