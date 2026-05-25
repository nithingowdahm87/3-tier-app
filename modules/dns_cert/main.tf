# DNS + ACM Certificate Module
# Creates ACM cert with DNS validation, Route53 A record, health checks + failover routing

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle { create_before_destroy = true }

  tags = merge(var.tags, { Name = "${var.domain_name}-cert" })
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# MAANG: Route53 health check on primary NLB
resource "aws_route53_health_check" "primary" {
  fqdn              = var.nlb_dns_name
  port              = 443
  type              = "TCP"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, { Name = "${var.name_prefix}-primary-health-check" })
}

resource "aws_route53_health_check" "secondary" {
  fqdn              = var.secondary_nlb_dns_name
  port              = 443
  type              = "TCP"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, { Name = "${var.name_prefix}-secondary-health-check" })
}

# MAANG: Failover routing — DNS automatically shifts to secondary if primary goes unhealthy
resource "aws_route53_record" "primary" {
  zone_id         = var.hosted_zone_id
  name            = var.domain_name
  type            = "A"
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  failover_routing_policy { type = "PRIMARY" }

  alias {
    name                   = var.nlb_dns_name
    zone_id                = var.nlb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id        = var.hosted_zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "secondary"
  health_check_id = aws_route53_health_check.secondary.id

  failover_routing_policy { type = "SECONDARY" }

  alias {
    name                   = var.secondary_nlb_dns_name
    zone_id                = var.secondary_nlb_zone_id
    evaluate_target_health = true
  }
}
