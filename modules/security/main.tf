resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "External ALB SG - allows HTTP and HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0   to_port = 0   protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Web tier SG - allows traffic only from ALB and bastion"
  vpc_id      = var.vpc_id

  ingress { from_port = 80 to_port = 80 protocol = "tcp" security_groups = [aws_security_group.alb.id] }
  ingress { from_port = 22 to_port = 22 protocol = "tcp" security_groups = [aws_security_group.bastion.id] }
  egress  { from_port = 0  to_port = 0  protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-web-sg" })
}

resource "aws_security_group" "internal_alb" {
  name        = "${var.name_prefix}-internal-alb-sg"
  description = "Internal ALB SG - allows traffic only from web tier"
  vpc_id      = var.vpc_id

  ingress { from_port = 8080 to_port = 8080 protocol = "tcp" security_groups = [aws_security_group.web.id] }
  egress  { from_port = 0    to_port = 0    protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-internal-alb-sg" })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "App tier SG - allows traffic only from internal ALB and bastion"
  vpc_id      = var.vpc_id

  ingress { from_port = 8080 to_port = 8080 protocol = "tcp" security_groups = [aws_security_group.internal_alb.id] }
  ingress { from_port = 22   to_port = 22   protocol = "tcp" security_groups = [aws_security_group.bastion.id] }
  egress  { from_port = 0    to_port = 0    protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg" })
}

resource "aws_security_group" "aurora" {
  name        = "${var.name_prefix}-aurora-sg"
  description = "Aurora SG - allows MySQL only from app tier"
  vpc_id      = var.vpc_id

  ingress { from_port = 3306 to_port = 3306 protocol = "tcp" security_groups = [aws_security_group.app.id] }
  egress  { from_port = 0    to_port = 0    protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-aurora-sg" })
}

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Bastion SG - SSH restricted to known CIDR only"
  vpc_id      = var.vpc_id

  ingress { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.bastion_allowed_cidr] }
  egress  { from_port = 0  to_port = 0  protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = merge(var.tags, { Name = "${var.name_prefix}-bastion-sg" })
}
