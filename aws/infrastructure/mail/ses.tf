resource "aws_ses_configuration_set" "runningdinner" {
  name = "runyourdinner"
  reputation_metrics_enabled = true
}

resource "aws_ses_domain_identity" "runningdinner" {
  domain = "mailing.${var.domain_name}"

}

resource "aws_route53_record" "runningdinner_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.runningdinner.domain}"
  type    = "TXT"
  ttl     = "300"
  records = [aws_ses_domain_identity.runningdinner.verification_token]
}

resource "aws_ses_domain_dkim" "runningdinner" {
  domain = aws_ses_domain_identity.runningdinner.domain
  depends_on = [aws_route53_record.runningdinner_amazonses_verification_record]
}

resource "aws_route53_record" "runningdinner_amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = "${aws_ses_domain_dkim.runningdinner.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.runningdinner.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_ses_domain_dkim.runningdinner.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "runningdinner" {
  domain = aws_ses_domain_identity.runningdinner.id
  depends_on = [aws_route53_record.runningdinner_amazonses_dkim_record]
}

# SPF
resource "aws_ses_domain_mail_from" "runningdinner" {
  domain           = aws_ses_domain_identity.runningdinner.domain
  mail_from_domain = "noreply.${aws_ses_domain_identity.runningdinner.domain}"
  depends_on = [aws_ses_domain_identity_verification.runningdinner]
}

# Route53 MX record for SPF
resource "aws_route53_record" "runningdinner_ses_domain_mail_from_mx" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = aws_ses_domain_mail_from.runningdinner.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"] # Change to the region in which `aws_ses_domain_identity.example` is created
}

# Route53 TXT record for SPF
resource "aws_route53_record" "example_ses_domain_mail_from_txt" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = aws_ses_domain_mail_from.runningdinner.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}

# SMTP User
resource "aws_iam_user" "ses_user" {
  name = "ses-smtp-user"
}

resource "aws_iam_access_key" "ses_user" {
  user = aws_iam_user.ses_user.name
}

resource  "aws_iam_policy" "ses_user_policy" {
  name = "ses-smtp-user-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "ses:SendRawEmail",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ses:SendEmail",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ses:GetSendStatistics",
        "Resource": "*"
      }
    ]
}
  POLICY
}

resource "aws_iam_user_policy_attachment" "ses_user_policy_attachment" {
  user = aws_iam_user.ses_user.name
  policy_arn = aws_iam_policy.ses_user_policy.arn
}

resource "aws_ssm_parameter" "ses_user_smtp_username" {
  type = "SecureString"
  name = "/runningdinner/ses/smtp/username"
  value = aws_iam_access_key.ses_user.id
}

resource "aws_ssm_parameter" "ses_user_smtp_password" {
  type = "SecureString"
  name = "/runningdinner/ses/smtp/password"
  value = aws_iam_access_key.ses_user.secret
}
