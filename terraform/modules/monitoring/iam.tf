resource "aws_iam_role" "monitoring" {
  name = "innovatech-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

// cant put role on the ec2 directly so i needed an instance profile
resource "aws_iam_instance_profile" "monitoring" {
  name = "innovatech-monitoring-profile"
  role = aws_iam_role.monitoring.name
}



// easier to get into the instace if needed
resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}




// Instance role policy to push alerts
resource "aws_iam_role_policy" "monitoring_sns_publish" {
  name = "grafana-sns-publish"
  role = aws_iam_role.monitoring.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = var.soar_alerts_topic_arn
    }]
  })
}
