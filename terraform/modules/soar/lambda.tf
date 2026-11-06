resource "aws_iam_role" "responder" {
  name = "innovatech-soar-responder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

// write logs to cloudwatch
resource "aws_iam_role_policy_attachment" "responder_logs" {
  role       = aws_iam_role.responder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// create/delete its network interfaces in the SOAR subnets
resource "aws_iam_role_policy_attachment" "responder_vpc" {
  role       = aws_iam_role.responder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

// perms for read/delete from alerts queue
resource "aws_iam_role_policy" "responder_sqs" {
  role = aws_iam_role.responder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = aws_sqs_queue.alerts.arn
    }]
  })
}

// set the dedupe lock, and remove it again if the block fails
resource "aws_iam_role_policy" "responder_dynamodb" {
  role = aws_iam_role.responder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:DeleteItem"]
      Resource = aws_dynamodb_table.incidents.arn
    }]
  })
}

// read the pfSense API key only
resource "aws_iam_role_policy" "responder_ssm" {
  role = aws_iam_role.responder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = aws_ssm_parameter.pfsense_api_key.arn
    }]
  })
}







data "archive_file" "responder" { // package the python code of the Lambda
  type        = "zip"
  source_file = "${path.module}/lambda/soar_responder.py"
  output_path = "${path.module}/lambda/soar_responder.zip"
}



resource "aws_cloudwatch_log_group" "responder" { // for reports
  name              = "/aws/lambda/innovatech-soar-responder"
  retention_in_days = 14
}



resource "aws_lambda_function" "responder" {
  function_name    = "innovatech-soar-responder"
  role             = aws_iam_role.responder.arn
  runtime          = "python3.13"
  handler          = "soar_responder.handler"
  filename         = data.archive_file.responder.output_path
  source_code_hash = data.archive_file.responder.output_base64sha256
  timeout          = 15 // 15 seconds because there is 100 sec visibility




  // run inside the SOAR subnets so it can reach pfSense over the VPN
  vpc_config {
    subnet_ids         = var.soar_subnet_ids
    security_group_ids = [aws_security_group.responder.id]
  }




  // settings the python code reads at start
  environment {
    variables = {
      TABLE_NAME        = aws_dynamodb_table.incidents.name
      ALLOWLIST         = join(",", var.allowlist)
      BLOCK_HOURS       = tostring(var.block_hours)
      PFSENSE_URL       = var.pfsense_url
      BLOCK_ALIAS       = var.block_alias
      PFSENSE_KEY_PARAM = aws_ssm_parameter.pfsense_api_key.name
    }
  }

  depends_on = [ // wait for these to exist first
    aws_cloudwatch_log_group.responder,
    aws_iam_role_policy.responder_sqs,
    aws_iam_role_policy.responder_dynamodb,
    aws_iam_role_policy.responder_ssm,
    aws_iam_role_policy_attachment.responder_logs,
    aws_iam_role_policy_attachment.responder_vpc,
  ]
}

// checks the SQS queue every few seconds and hands new messages to the Lambda
resource "aws_lambda_event_source_mapping" "alerts" {
  event_source_arn        = aws_sqs_queue.alerts.arn
  function_name           = aws_lambda_function.responder.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"] // partial batch response

  scaling_config {
    maximum_concurrency = 2 // limit responder numbers
  }
}



resource "aws_security_group" "responder" {
  name        = "innovatech-soar-responder-sg"
  description = "SOAR Lambda - outbound HTTPS only"
  vpc_id      = var.internal_vpc_id

  tags = {
    Name = "innovatech-soar-responder-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "responder_https" {
  security_group_id = aws_security_group.responder.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}