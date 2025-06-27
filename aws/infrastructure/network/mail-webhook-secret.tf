resource "random_password" "mail-webhook-secret" {
  length           = 32
  special          = false
}

resource "aws_ssm_parameter" "mail-webhook-secret" {
  type = "SecureString"
  name = "/runningdinner/mail/webhook/secret"
  tags = local.common_tags
  value = random_password.mail-webhook-secret.result
}
