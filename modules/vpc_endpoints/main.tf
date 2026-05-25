terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

data "aws_region" "current" {}

# Security group for Interface endpoints
resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Allow HTTPS from private subnets to VPC Interface endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc-endpoints-sg" })
}

# Gateway endpoints (free — no hourly charge)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  tags              = merge(var.tags, { Name = "${var.name_prefix}-s3-endpoint" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  tags              = merge(var.tags, { Name = "${var.name_prefix}-dynamodb-endpoint" })
}

# Interface endpoints (traffic stays on AWS backbone)
locals {
  interface_services = [
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "monitoring",
    "logs",
    "ecr.api",
    "ecr.dkr",
    "xray",
    "kms",
  ]
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each = toset(local.interface_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-${each.key}-endpoint" })
}
