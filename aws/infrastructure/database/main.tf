provider "aws" {
  region  = var.region
  profile = var.aws_profile
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-${var.stage}"
    session_name = "terraform-database"
  }
}

terraform {
  backend "s3" {
    key = "services/db-v2.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0, !=5.39"
    }
  }
}
