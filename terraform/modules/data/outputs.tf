output "db_secret_arn" {
  value = aws_db_instance.primary.master_user_secret[0].secret_arn
}

output "db_name" {
  value = aws_db_instance.primary.db_name
}
