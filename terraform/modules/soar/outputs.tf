output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "alerts_queue_arn" {
  value = aws_sqs_queue.alerts.arn
}

output "alerts_queue_url" {
  value = aws_sqs_queue.alerts.id
}

output "alerts_dlq_arn" {
  value = aws_sqs_queue.alerts_dlq.arn
}