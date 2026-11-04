resource "aws_security_group" "monitoring" {
  name        = "innovatech-monitoring-sg"
  description = "Monitoring servers - HTTP from the ALB only"
  vpc_id      = var.internal_vpc_id

  tags = {
    Name = "innovatech-monitoring-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "loki_from_collector" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = var.collector_cidr
  from_port         = 3100
  to_port           = 3100
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "grafana_from_admin" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "monitoring_https_out" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "monitoring_http_out" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_from_collector" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = var.collector_cidr
  from_port         = 9090
  to_port           = 9090
  ip_protocol       = "tcp"
}
