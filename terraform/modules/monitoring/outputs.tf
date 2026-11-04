output "instance_id" {
  value = aws_instance.monitoring.id
}

output "private_ip" {
  value = aws_instance.monitoring.private_ip
}
