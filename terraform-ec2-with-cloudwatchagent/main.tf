#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

provider "aws" {
  region     = "ap-southeast-1"
}
variable "keyName" {
  default = "my-kp-default"
}
variable "vpcid" {
  default = "vpc-034cff70368626c7c"
}
# alb需要绑定是公共子网，EC2可以放到私有子网（需要能outbound到公网，配置NATGW）
variable "subnetIds" {
  default = ["subnet-02f97a1249de8aea6", "subnet-044cbb1fa31785d73", "subnet-039d6134943390131"]
}
variable "securityGroups" {
  default = ["sg-076119acee410effb"]
}


data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "vpc" {
  id = var.vpcid
}


  # 创建一个安全组
# resource "aws_security_group" "web_security_group" {
#     name_prefix = "godemo"
#     vpc_id      = "${var.vpcid}"

#     ingress {
#       from_port = 80
#       to_port   = 80
#       protocol  = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }
resource "aws_network_interface" "ss" {
  count           = var.cluster_size
  subnet_id       = element(var.subnetIds, count.index)
  security_groups = var.securityGroups
}  
resource "aws_iam_role" "sts" {
  name = "godemo-sts-role"

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
        "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ss" {
  name = "godemo-instance-profile"
  role = aws_iam_role.sts.name
}

resource "aws_launch_template" "ss" {
  name                                 = "goapp-launch-template"
  image_id                             = var.image_id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ss.name
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
      Name = "godemo"
    }
  }
}

resource "aws_autoscaling_group" "ss" {
  name                      = "go-demo-asg"
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

resource "aws_lb" "ss" {
  name               = "go-demo-internal-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.securityGroups
  enable_deletion_protection = false

  dynamic "subnet_mapping" {
    for_each = var.subnetIds
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name = "godemo-alb"
  }
}

resource "aws_lb_target_group" "ss_tg" {
  name               = "godemo-lb-tg"
  port               = 8080
  protocol           = "HTTP"
  vpc_id             = var.vpcid


  health_check {
    path = "/ping"
  }

  tags = {
    Name = "godemo-target-grp"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_lb" {
  autoscaling_group_name = aws_autoscaling_group.ss.id
  lb_target_group_arn    = aws_lb_target_group.ss_tg.arn
}


resource "aws_lb_listener" "ss" {
  load_balancer_arn = aws_lb.ss.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ss_tg.arn
  }

  tags = {
    Name = "go-demo"
  }
}

