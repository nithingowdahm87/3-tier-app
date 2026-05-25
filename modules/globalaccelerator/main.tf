terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Global Accelerator — routes users to nearest AWS edge, keeps traffic on AWS backbone
resource "aws_globalaccelerator_accelerator" "this" {
  name            = "${var.name_prefix}-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = var.flow_logs_bucket
    flow_logs_s3_prefix = "global-accelerator/"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-global-accelerator" })
}

resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

# Endpoint group pointing to primary NLB
resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.https.id
  endpoint_group_region = var.primary_region
  traffic_dial_percentage = 100

  health_check_port             = 443
  health_check_protocol         = "TCP"
  health_check_interval_seconds = 10
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id                    = var.primary_nlb_arn
    weight                         = 100
    client_ip_preservation_enabled = false
  }
}

# Endpoint group pointing to secondary NLB (failover)
resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn            = aws_globalaccelerator_listener.https.id
  endpoint_group_region   = var.secondary_region
  traffic_dial_percentage = 0

  health_check_port             = 443
  health_check_protocol         = "TCP"
  health_check_interval_seconds = 10
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id                    = var.secondary_nlb_arn
    weight                         = 100
    client_ip_preservation_enabled = false
  }
}
