locals {
  asg_name = "innovatech-web-asg"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}


resource "aws_launch_template" "web" {
  name_prefix            = "innovatech-web-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    apt-get update -y
    apt-get install -y nginx

    TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
    INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

    echo "<h1>Innovatech</h1><p>Served by $INSTANCE_ID in $AZ</p>" > /var/www/html/index.html

    systemctl enable --now nginx
  EOF
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-web"
    }
  }
}


resource "aws_autoscaling_group" "web" {
  name                = local.asg_name
  vpc_zone_identifier = var.web_subnet_ids
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  initial_lifecycle_hook {
    name                 = "register-ip"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result       = "ABANDON"
    heartbeat_timeout    = 300
  }

  initial_lifecycle_hook {
    name                 = "deregister-ip"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }

  tag {
    key                 = "Name"
    value               = "innovatech-web"
    propagate_at_launch = true
  }

  depends_on = [aws_cloudwatch_event_target.asg_lifecycle, aws_lambda_permission.eventbridge]
}
