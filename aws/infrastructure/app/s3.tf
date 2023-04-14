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
}

resource "aws_s3_bucket_acl" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  acl = "public-read"
#  depends_on = [ aws_s3_bucket_public_access_block.webapp ]
}

data "aws_iam_policy_document" "webapp" {
  statement {
    sid = "AllowPublicReadonlyAccess"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.webapp.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  policy = data.aws_iam_policy_document.webapp.json
}


#resource "aws_s3_bucket_public_access_block" "webapp" {
#  bucket = aws_s3_bucket.webapp.id
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}
