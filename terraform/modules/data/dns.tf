resource "aws_route53_record" "db" {
  zone_id = var.zone_id
  name    = "database"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.primary.address]

}