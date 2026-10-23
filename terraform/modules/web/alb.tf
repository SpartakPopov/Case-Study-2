resource "aws_security_group" "alb" {
  name        = "innovatech-alb-sg"
  description = "Public web access to the ALB"
  vpc_id      = var.dmz_vpc_id

  tags = {
    Name = "innovatech-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  for_each          = toset(var.web_subnet_cidrs)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}



resource "aws_lb" "web" {
  name                       = "innovatech-web-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.dmz_public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true

  tags = {
    Name = "innovatech-web-alb"
  }
}


resource "aws_lb_target_group" "web" {
  name                 = "innovatech-web-tg"
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 30
  vpc_id               = var.dmz_vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = {
    Name = "innovatech-web-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}