terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_globalaccelerator_accelerator" "this" {
  name            = "${var.name_prefix}-ga"
  ip_address_type = "IPV4"
  enabled         = true
  tags            = merge(var.tags, { Name = "${var.name_prefix}-ga" })
}

resource "aws_globalaccelerator_listener" "this" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.this.id
  endpoint_group_region = var.primary_region

  endpoint_configuration {
    endpoint_id = var.nlb_primary_arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn          = aws_globalaccelerator_listener.this.id
  endpoint_group_region = var.secondary_region

  endpoint_configuration {
    endpoint_id = var.nlb_secondary_arn
    weight      = 100
  }
}
