resource "aws_db_subnet_group" "db" {
  name       = "innovatech-db-subnets"
  subnet_ids = var.data_subnet_ids

  tags = {
    Name = "innovatech-db-subnets"
  }
}

resource "aws_db_parameter_group" "db" {
  name   = "innovatech-mysql84"
  family = "mysql8.4"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }
}

resource "aws_db_instance" "primary" {
  identifier        = "innovatech-db"
  engine            = "mysql"
  engine_version    = "8.4"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "innovatech"
  username                    = "admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  parameter_group_name        = aws_db_parameter_group.db.name
  multi_az                    = var.multi_az
  publicly_accessible         = false

  backup_retention_period    = 7
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:05:00-sun:06:00"
  auto_minor_version_upgrade = true

  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = {
    Name = "innovatech-db"
  }
}