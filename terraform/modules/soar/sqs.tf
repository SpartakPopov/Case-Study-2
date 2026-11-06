resource "aws_sqs_queue" "alerts" {
  name                       = "innovatech-soar-alerts"
  visibility_timeout_seconds = 100
  message_retention_seconds  = 300000
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.alerts_dlq.arn
    "maxReceiveCount"     = 5
  })
}


resource "aws_sqs_queue" "alerts_dlq" {
  name                      = "innovatech-soar-alerts-dlq"
  message_retention_seconds = 1000000
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "alerts" {
  queue_url = aws_sqs_queue.alerts.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*" // uses only my arn so it doesnt really matter
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.alerts.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.alerts.arn // here
          }
        }
      }
    ]
  })
}

