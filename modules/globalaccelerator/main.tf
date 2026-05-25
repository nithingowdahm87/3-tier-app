terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_globalaccelerator_accelerator" "this" {
  name            = "${var.name_prefix}-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = var.logs_bucket_name
    flow_logs_s3_prefix = "global-accelerator/"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-accelerator" })
}

resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.https.id
  endpoint_group_region = var.primary_region
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id                    = var.primary_nlb_arn
    weight                         = 100
    client_ip_preservation_enabled = true
  }

  health_check_path             = "/health"
  health_check_port             = 443
  health_check_protocol         = "HTTPS"
  health_check_interval_seconds = 30
  threshold_count               = 3
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn          = aws_globalaccelerator_listener.https.id
  endpoint_group_region = var.secondary_region
  traffic_dial_percentage = 0

  endpoint_configuration {
    endpoint_id                    = var.secondary_nlb_arn
    weight                         = 100
    client_ip_preservation_enabled = true
  }

  health_check_path             = "/health"
  health_check_port             = 443
  health_check_protocol         = "HTTPS"
  health_check_interval_seconds = 30
  threshold_count               = 3
}
