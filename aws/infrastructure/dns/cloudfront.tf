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

resource "aws_cloudfront_distribution" "runningdinner" {
  enabled = true

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
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    # acm_certificate_arn = aws_acm_certificate.runningdinner.arn
  }
}