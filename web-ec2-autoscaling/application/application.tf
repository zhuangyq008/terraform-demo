resource "aws_iam_role" "sts" {
  name = "devax-godemo-sts-role"

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
  name = "devax-instance-profile"
  role = aws_iam_role.sts.name
}

resource "aws_launch_template" "devax" {
  name                                 = "devax-goapp-launch-template"
  image_id                             = var.app_ami
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
  vpc_security_group_ids = var.vpc_security_group_ids
  monitoring {
    enabled = true
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "godemo-app"
      Project = "devax-three-tier"
      Environment = "Dev"    
    }
  }
}
# resource "aws_launch_configuration" "terramino" {
#   name_prefix     = "devax-aws-asg-"
#   image_id        = var.app_ami
#   instance_type   = var.app_inst_type
#   #user_data       = file("user-data.sh")
#   user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
#     version    = var.app_version
#   }))  
#   security_groups = [aws_security_group.terramino_instance.id]

#   lifecycle {
#     create_before_destroy = true
#   }
# }
resource "aws_autoscaling_group" "devax" {
  name                      = "devax-demo-asg"
  vpc_zone_identifier       = var.vpc_zone_identifier
  desired_capacity          = 4
  min_size                  = 0
  max_size                  = 10
  
  mixed_instances_policy {

    instances_distribution {
      # on_demand_base_capacity = 2
      # on_demand_percentage_above_base_capacity = 50
      spot_allocation_strategy = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.devax.id
        version = "$Latest"
      }
      override {
        instance_type = "t3.medium"
        weighted_capacity = "3"
      }

      override {
        instance_type = "t2.micro"
        weighted_capacity = "2"
      }

    }
    
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}
 resource "aws_lb_target_group" "devax" {
   name     = "devax-asg"
   port     = 8080
   protocol = "HTTP"
   vpc_id   = var.vpc_id
   health_check {
     path = "/ping"
     interval = 15
   }   
 }

resource "aws_autoscaling_attachment" "devax" {
  autoscaling_group_name = aws_autoscaling_group.devax.id
  lb_target_group_arn   = aws_lb_target_group.devax.arn
}
resource "aws_lb" "devax" {
  name               = "devax-asg-terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb_security_groups
  subnets            = var.public_subnets
}
resource "aws_lb_listener" "devax" {
  load_balancer_arn = aws_lb.devax.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devax.arn
  }
}