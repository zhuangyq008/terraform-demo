terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.0"
    }
  }
}

provider "aws" {
  region     = "ap-southeast-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "vpc" {
  id = var.vpcid
}

resource "aws_iam_role" "sts" {
  name = "ssmdemo-sts-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ss" {
  name = "ssmdemo-policy"
  role = aws_iam_role.sts.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "cloudwatch:PutMetricData",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "ssm:UpdateInstanceInformation",
        "ssm:GetDocument",
        "ssm:SendCommand",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ssmprofile" {
  name = "ssmdemo-instance-profile"
  role = aws_iam_role.sts.name
}

resource "aws_launch_template" "ss" {
  name                                 = "ssmdemo-launch-template"
  image_id                             = var.image_id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ssmprofile.name
  }

  user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
    version    = var.app_version
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  vpc_security_group_ids = var.securityGroups
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ssmdemo"
    }
  }
}

resource "aws_autoscaling_group" "ss" {
  name                      = "ssm-demo-asg"
  availability_zones        = data.aws_availability_zones.available.names
  
  desired_capacity          = 3
  min_size                  = 1
  max_size                  = 3

  launch_template {
    id      = aws_launch_template.ss.id
    version = "$Latest"
  }
  
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}








