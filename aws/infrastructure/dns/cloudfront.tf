
data "aws_instance" "runningdinner-app-instance" {
  filter {
    name   = "tag:Name"
    values = [var.app_instance_name]
  }
  filter {
    name = "instance-state-name"
    values = ["running"]
  }
}


data "aws_s3_bucket" "webapp" {
  bucket = var.webapp_bucket_name
}

data "aws_iam_policy_document" "webapp" {
  statement {
    actions   = ["s3:*"]
    resources = [data.aws_s3_bucket.webapp.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.webapp-cloudfront-access.iam_arn]
    }
  }
}
resource "aws_s3_bucket_policy" "webapp" {
  bucket = data.aws_s3_bucket.webapp.id
  policy = data.aws_iam_policy_document.webapp.json
}

resource "aws_cloudfront_origin_access_identity" "webapp-cloudfront-access" {
  comment = "Allows access of webapp bucket from Cloudfront"
}

resource "aws_cloudfront_distribution" "runningdinner" {
  enabled = true

  logging_config {
    bucket = aws_s3_bucket.webapp-access-logs.bucket_domain_name
    prefix = "logs/"
  }

  custom_error_response {
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "runningdinner-app"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = []
    }
  }

  ordered_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["HEAD", "GET"]
    path_pattern           = "/rest"
    target_origin_id       = "runningdinner-app"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    max_ttl = 120
    min_ttl = 0
    default_ttl = 0
  }

  origin {
    domain_name = data.aws_instance.runningdinner-app-instance.public_dns
    origin_id   = "runningdinner-app"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = data.aws_s3_bucket.webapp.bucket_regional_domain_name
    origin_id   = aws_cloudfront_origin_access_identity.webapp-cloudfront-access.cloudfront_access_identity_path
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.webapp-cloudfront-access.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = aws_acm_certificate.runningdinner.arn
    ssl_support_method = "sni-only"
  }

  aliases = [var.domain_name]
}

# *** Bucket and Permissions for Cloudfront logs
resource "aws_s3_bucket" "webapp-access-logs" {
  bucket = "${data.aws_s3_bucket.webapp.bucket_domain_name}-accesslogs"
  tags = local.common_tags
  force_destroy = true
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_acl" "webapp-access-logs" {
  bucket = aws_s3_bucket.webapp-access-logs.id
  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }
    grant {
      grantee {
        type = "CanonicalUser"
        id = data.aws_canonical_user_id.current.id
      }
      permission = "FULL_CONTROL"
    }
    grant {
      grantee {
        type = "CanonicalUser"
        # Harcoded ID of awslogsdelievery (see https://stackoverflow.com/questions/67182159/cloudfront-distribution-s3-logging-not-working or https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html)
        id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      }
      permission = "FULL_CONTROL"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "webapp-access-logs" {
  bucket = aws_s3_bucket.webapp-access-logs.id
  rule {
    id     = "Expire7Days"
    status = "Enabled"
    expiration {
      days = 7
    }
  }
}

data "aws_iam_policy_document" "webapp-access-logs" {
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.webapp-access-logs.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.webapp-cloudfront-access.iam_arn]
    }
  }
}
resource "aws_s3_bucket_policy" "webapp-access-logs" {
  bucket = aws_s3_bucket.webapp-access-logs.id
  policy = data.aws_iam_policy_document.webapp-access-logs.json
}

resource "aws_s3_bucket_public_access_block" "webapp-access-logs" {
  bucket = aws_s3_bucket.webapp-access-logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# *** End Bucket and Permissions for Cloudfront logs