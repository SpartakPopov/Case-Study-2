data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_iam_role" "register_targets" {
  name = "innovatech-web-target-registration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "register_targets_logs" {
  role       = aws_iam_role.register_targets.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "register_targets" {
  role = aws_iam_role.register_targets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets"]
        Resource = aws_lb_target_group.web.arn
      },
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:DescribeTargetHealth", "ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "autoscaling:CompleteLifecycleAction"
        Resource = "arn:aws:autoscaling:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.asg_name}"
      }
    ]
  })
}


data "archive_file" "register_targets" {
  type        = "zip"
  source_file = "${path.module}/lambda/register_targets.py"
  output_path = "${path.module}/lambda/register_targets.zip"
}


resource "aws_cloudwatch_log_group" "register_targets" {
  name              = "/aws/lambda/innovatech-web-target-registration"
  retention_in_days = 14
}


resource "aws_lambda_function" "register_targets" {
  function_name    = "innovatech-web-target-registration"
  role             = aws_iam_role.register_targets.arn
  runtime          = "python3.13"
  handler          = "register_targets.handler"
  filename         = data.archive_file.register_targets.output_path
  source_code_hash = data.archive_file.register_targets.output_base64sha256
  timeout          = 180

  environment {
    variables = {
      TARGET_GROUP_ARN = aws_lb_target_group.web.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.register_targets,
    aws_iam_role_policy.register_targets,                // improvement over the earlier version:
    aws_iam_role_policy_attachment.register_targets_logs // permissions exist before it can run
  ]
}


resource "aws_cloudwatch_event_rule" "asg_lifecycle" {
  name = "innovatech-web-asg-lifecycle"

  event_pattern = jsonencode({
    source        = ["aws.autoscaling"]
    "detail-type" = ["EC2 Instance-launch Lifecycle Action", "EC2 Instance-terminate Lifecycle Action"]
    detail        = { AutoScalingGroupName = [local.asg_name] }
  })
}

resource "aws_cloudwatch_event_target" "asg_lifecycle" {
  rule = aws_cloudwatch_event_rule.asg_lifecycle.name
  arn  = aws_lambda_function.register_targets.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_targets.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_lifecycle.arn
}
