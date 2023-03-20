provider "aws" {
  region  = var.region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-${var.stage}"
    session_name = "terraform-dns"
  }
}

terraform {
  backend "s3" {
    key = "services/dns_v2.tfstate"
  }
}

# See https://github.com/hashicorp/terraform/issues/2283
locals {
  common_tags = tomap({
    "service" = "runningdinner-v2"
    "component" = "app"
  })
}