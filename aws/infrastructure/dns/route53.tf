resource "aws_route53_zone" "runningdinner" {
  name = "${var.domain_name}."
  comment = "HostedZone created by Route53 Registrar"
  tags = local.common_tags
}

resource "aws_route53_record" "google-site-verification" {
  name = var.domain_name
  type = "TXT"
  zone_id = aws_route53_zone.runningdinner.id
  records = ["google-site-verification=mkZzpyYlrX3vVbFf70RZyxkKMvVDpf8WowRfapqjPtg"]
  ttl = 300
}

resource "aws_route53_record" "sendgrid-s1-domainkey" {
  name = "s1._domainkey.runyourdinner.eu"
  type = "CNAME"
  zone_id = aws_route53_zone.runningdinner.id
  records = ["s1.domainkey.u3158000.wl001.sendgrid.net"]
  ttl = 300
}

resource "aws_route53_record" "sendgrid-s2-domainkey" {
  name = "s2._domainkey.runyourdinner.eu"
  type = "CNAME"
  zone_id = aws_route53_zone.runningdinner.id
  records = ["s2.domainkey.u3158000.wl001.sendgrid.net"]
  ttl = 300
}

resource "aws_route53_record" "sendgrid-mail" {
  name = "mail.runyourdinner.eu"
  type = "CNAME"
  zone_id = aws_route53_zone.runningdinner.id
  records = ["u3158000.wl001.sendgrid.net"]
  ttl = 300
}

resource "aws_acm_certificate" "runningdinner" {
  depends_on = [null_resource.add-nameservers-to-root-account]
  domain_name = var.domain_name
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
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.runningdinner.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.runningdinner.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "null_resource" "add-nameservers-to-root-account" {
  depends_on = [ aws_route53_zone.runningdinner ]
  provisioner "local-exec" {
    command = <<EOF
      ${path.module}/../../scripts/add-nameservers.sh "prod" "${var.stage}" ${join(" ", aws_route53_zone.runningdinner.name_servers)}
    EOF
  }
}