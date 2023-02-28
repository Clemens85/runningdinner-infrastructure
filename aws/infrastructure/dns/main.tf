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
