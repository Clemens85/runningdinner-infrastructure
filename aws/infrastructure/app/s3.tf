locals {
  webapp-s3bucket-name = var.webapp_bucket_name
  web-s3bucket-arn  = "arn:aws:s3:::${local.webapp-s3bucket-name}"
}

resource "aws_s3_bucket" "webapp" {
  bucket = local.webapp-s3bucket-name
  tags = local.common_tags
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  index_document {
    suffix = "index.html"
  }
#  routing_rule {
#    condition {
#
#    }
#    redirect {
#
#    }
#  }
}

resource "aws_s3_bucket_acl" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  acl = "private"
}

resource "aws_s3_bucket_public_access_block" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#resource "null_resource" "deploy-files" {
#  depends_on = [ aws_s3_bucket.webapp ]
#  provisioner "local-exec" {
#    command = <<EOF
#      ${path.module}/../../scripts/deploy-s3-content.sh "${var.stage}" "${local.webapp-s3bucket-name}"
#    EOF
#  }
#}