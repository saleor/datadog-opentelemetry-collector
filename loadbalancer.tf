locals {
  nlb_name  = "${var.name}-private"
  otlp_port = 4317
}

resource "aws_security_group" "private_nlb" {
  name   = local.nlb_name
  vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_otlp" {
  security_group_id = aws_security_group.private_nlb.id

  cidr_ipv4   = aws_vpc.vpc.cidr_block
  ip_protocol = "tcp"
  from_port   = local.otlp_port
  to_port     = local.otlp_port

  description = "Allow OTLP traffic from VPC"
}
resource "aws_vpc_security_group_ingress_rule" "privatelink_otlp" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.private_nlb.id

  cidr_ipv4   = each.value
  ip_protocol = "tcp"
  from_port   = local.otlp_port
  to_port     = local.otlp_port
  description = "Allow OTLP traffic from Privatelink"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.private_nlb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  description = "Allow all outbound traffic"
}
resource "aws_lb" "private_nlb" {
  name               = local.nlb_name
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.private_nlb.id]
  subnets            = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_lb_listener" "otlp" {
  load_balancer_arn = aws_lb.private_nlb.arn
  port              = local.otlp_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.otlp.arn
  }
}
