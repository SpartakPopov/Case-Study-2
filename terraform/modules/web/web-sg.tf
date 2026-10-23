resource "aws_security_group" "web" {
  name        = "innovatech-web-sg"
  description = "Web servers - HTTP from the ALB only"
  vpc_id      = var.internal_vpc_id

  tags = {
    Name = "innovatech-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  for_each          = toset(var.dmz_public_subnet_cidrs)
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_https_out" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_http_out" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
