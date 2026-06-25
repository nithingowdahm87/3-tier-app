terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.us_east_1]
    }
  }
}

locals {
  use_acm_cert = var.acm_certificate_arn != "" && !strcontains(var.acm_certificate_arn, "REPLACE") && !strcontains(var.acm_certificate_arn, "123456789012")
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  web_acl_id          = var.waf_acl_arn != "" ? var.waf_acl_arn : null
  tags                = merge(var.tags, { Name = "${var.name_prefix}-cdn" })

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]
      cookies {
        forward = "all"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.use_acm_cert ? var.acm_certificate_arn : null
    ssl_support_method             = local.use_acm_cert ? "sni-only" : null
    minimum_protocol_version       = local.use_acm_cert ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !local.use_acm_cert
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
