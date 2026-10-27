resource "aws_security_group" "db" {
  name   = "innovatech-db-sg"
  vpc_id = var.internal_vpc_id

  tags = {
    Name = "innovatech-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.web_sg_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}


resource "aws_vpc_security_group_ingress_rule" "db_from_monitoring" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = var.monitoring_subnet_cidr
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}