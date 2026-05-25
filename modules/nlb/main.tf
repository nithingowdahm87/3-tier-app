terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_lb" "nlb" {
  name               = "${var.name_prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb" })
}

# TCP:80 listener → forward to ALB
resource "aws_lb_target_group" "alb_http" {
  name        = "${var.name_prefix}-nlb-alb-http"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "alb_http" {
  target_group_arn = aws_lb_target_group.alb_http.arn
  target_id        = var.alb_arn
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_http.arn
  }
}

# TCP:443 listener → forward to ALB
resource "aws_lb_target_group" "alb_https" {
  name        = "${var.name_prefix}-nlb-alb-https"
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    enabled             = true
    protocol            = "HTTPS"
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "alb_https" {
  target_group_arn = aws_lb_target_group.alb_https.arn
  target_id        = var.alb_arn
  port             = 443
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_https.arn
  }
}
