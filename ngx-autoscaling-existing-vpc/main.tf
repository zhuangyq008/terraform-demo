provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

variable "vpc_id" {
    default = "vpc-0533d70a4f51d42c7"
}
variable "app_inst_type" {
  default = "t3.medium"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}
variable "security_group_id_instance" {
    default = "sg-0562c799bf21129bc"
}
variable "security_group_id_lb" {
    default = "sg-0d7578f51c28c1f16"
}
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = "Public"
  }
}
resource "aws_iam_role" "sts" {
  name = "nginx-instance-role"

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
  name = "godemo-policy"
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
resource "aws_iam_instance_profile" "ss" {
  name = "ngx-web-instance-profile"
  role = aws_iam_role.sts.name
}
data "aws_ami" "base" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  most_recent = true
}
# resource "aws_security_group" "terramino_instance" {
#   name = "learn-asg-terramino-instance"
#   ingress {
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     security_groups = [aws_security_group.terramino_lb.id]
#   }
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }  
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }  
#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_security_group.terramino_lb.id]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   vpc_id = var.vpc_id
# }

# resource "aws_security_group" "terramino_lb" {
#   name = "learn-asg-terramino-lb"
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   vpc_id = var.vpc_id
# }
data "aws_security_group" "instance" {
  id = var.security_group_id_instance
}
data "aws_security_group" "lb" {
  id = var.security_group_id_lb
}
resource "aws_launch_template" "devax" {
  name                                 = "ngx-web-launch-template"
  image_id                             = data.aws_ami.base.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.app_inst_type
  #key_name                             = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ss.name
  }

  user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
    version    = "1.1"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  vpc_security_group_ids = [data.aws_security_group.instance.id]
  monitoring {
    enabled = true
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "Ngx-Web"
      Owner = "Enginez"
      Environment = "Dev"    
    }
  }
}

resource "aws_autoscaling_group" "devax" {
  name                      = "ngx-web-demo-asg"
  vpc_zone_identifier       = data.aws_subnets.private.ids
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 10
  protect_from_scale_in     = true
  launch_template {
    id      = aws_launch_template.devax.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}
 resource "aws_lb_target_group" "ngx-web-tg" {
   name     = "ngx-web-tg"
   port     = 80
   protocol = "HTTP"
   vpc_id   = var.vpc_id
   health_check {
     path = "/"
     interval = 15
   }   
 }

resource "aws_autoscaling_attachment" "devax" {
  autoscaling_group_name = aws_autoscaling_group.devax.id
  lb_target_group_arn   = aws_lb_target_group.ngx-web-tg.arn
}
resource "aws_lb" "devax" {
  name               = "ngx-web-asg-terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb.id]
  subnets            = data.aws_subnets.public.ids
}
resource "aws_lb_listener" "devax" {
  load_balancer_arn = aws_lb.devax.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ngx-web-tg.arn
  }
}

output "alb_endpoint" {
  value = "http://${aws_lb.devax.dns_name}:${aws_lb_listener.devax.port}/"
}