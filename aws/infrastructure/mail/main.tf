provider "aws" {
  region  = var.region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-${var.stage}"
    session_name = "terraform-mail"
  }

  default_tags {
    tags = {
      service = "runningdinner-v2"
      component = "mail"
      stage = var.stage
    }
  }
}

terraform {
  backend "s3" {
    key = "services/mail.tfstate"
  }
}

data "aws_route53_zone" "runningdinner" {
  name = "${var.domain_name}."
}

data "aws_ssm_parameter" "mail-webhook-secret" {
  name = "/runningdinner/mail/webhook/secret"
}