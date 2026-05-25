resource "aws_lb" "nlb" {
  name               = "${var.name_prefix}-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets            = var.public_subnet_ids
  enable_cross_zone_load_balancing = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb" })
}

resource "aws_lb_target_group" "nlb_http" {
  name        = "${var.name_prefix}-nlb-tg-http"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    protocol = "HTTP"
    path     = "/health"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-tg-http" })
}

resource "aws_lb_listener" "nlb_http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_http.arn
  }
}

resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.nlb_http.arn
  target_id        = var.alb_arn
  port             = 80
}
