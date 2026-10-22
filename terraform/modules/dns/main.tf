resource "aws_route53_zone" "private_zone" {
  name = var.private_zone_name

  vpc {
    vpc_id = var.vpc_id
  }
  tags = {
    Name = "innovatech_private_zone"
  }
}