resource "aws_lb" "external" {
  name               = "${var.name_prefix}-alb-ext"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "${var.name_prefix}/alb-ext"
    enabled = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-ext" })
}

resource "aws_lb_target_group" "web" {
  name        = "${var.name_prefix}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path    = "/health"
    matcher = "200-299"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-web-tg" })
}

# HTTP listener redirects to HTTPS
resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener with ACM certificate termination and TLS 1.3 policy
resource "aws_lb_listener" "external_https" {
  load_balancer_arn = aws_lb.external.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb" "internal" {
  name               = "${var.name_prefix}-alb-int"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "${var.name_prefix}/alb-int"
    enabled = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-int" })
}

resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path    = "/actuator/health"
    matcher = "200-299"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-tg" })
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
