resource "aws_route53_zone" "runningdinner" {
  name = "dev.runyourdinner.eu."
  tags = local.common_tags
}

resource "aws_acm_certificate" "runningdinner" {
  domain_name = "dev.runyourdinner.eu"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.us-east-1
}

resource "aws_route53_record" "cert-validation" {
  zone_id = aws_route53_zone.runningdinner.id
  name    = tolist(aws_acm_certificate.runningdinner.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.runningdinner.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.runningdinner.domain_validation_options)[0].resource_record_value]
  ttl     = 90
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.runningdinner.arn
  validation_record_fqdns = [aws_route53_record.cert-validation.fqdn]
  provider = aws.us-east-1
}


resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.runningdinner.id
  name    = "dev.runyourdinner.eu"
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.runningdinner.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.runningdinner.hosted_zone_id
    evaluate_target_health = false
  }
}