terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region     = "us-east-1"
}
# 创建一个 VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}
# 创建一个Internet网关
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "Example-igw"
  }  
}
# resource "aws_nat_gateway" "example" {
#   allocation_id = aws_eip.example.id
#   subnet_id     = aws_subnet.public.id
# }
resource "aws_eip" "example" {
  vpc = true
}
# 创建一个子网
# resource "aws_subnet" "example" {
#   vpc_id     = aws_vpc.example.id
#   cidr_block = "10.0.1.0/24"
# }
# 创建两个子网，一个在 us-east-1a 可用区，一个在 us-east-1b 可用区
resource "aws_subnet" "example_a" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public-subnet"
  }
}

resource "aws_subnet" "example_b" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Public-subnet"
  }  
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.example_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.example_b.id
  route_table_id = aws_route_table.public.id
}
# 创建一个 ECS 集群
resource "aws_ecs_cluster" "example" {
  name = "example"
}

# 创建一个 ECS 服务
resource "aws_ecs_service" "example" {
  name            = "example"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1

  # 配置负载均衡
  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # 配置服务发现
  service_registries {
    registry_arn = aws_service_discovery_service.example.arn
  }

  # 配置网络
  network_configuration {
    security_groups = [aws_security_group.example.id]
    subnets         = [aws_subnet.example_a.id, aws_subnet.example_b.id]
  }
}

# 创建一个任务定义
resource "aws_ecs_task_definition" "example" {
  family                   = "example"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"

  # 定义容器
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx"
      memory    = 128
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}
# 创建一个安全组
resource "aws_security_group" "example" {
  name_prefix = "es_"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# 定义安全组规则
resource "aws_security_group_rule" "allow_http" {
  security_group_id = aws_security_group.example.id
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_https" {
  security_group_id = aws_security_group.example.id
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = aws_security_group.example.id
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


# 创建一个负载均衡目标组
resource "aws_lb_target_group" "example" {
  name_prefix      = "ecs"
  port             = 80
  protocol         = "HTTP"
  target_type      = "ip"
  vpc_id           = aws_vpc.example.id

}

# 创建一个服务发现服务
resource "aws_service_discovery_service" "example" {
  name                = "example"
  namespace_id        = aws_service_discovery_private_dns_namespace.example.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id
    dns_records {
      ttl  = 10
      type = "A"
    }    
    routing_policy = "MULTIVALUE"
  }
}

# 创建一个服务发现私有 DNS 命名空间
resource "aws_service_discovery_private_dns_namespace" "example" {
  name = "example"
  vpc  = aws_vpc.example.id
}
# 创建一个负载均衡器
resource "aws_lb" "example" {
  name               = "example"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.example_a.id,aws_subnet.example_b.id]
}

# 创建一个监听器
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example.arn
    type             = "forward"
  }
}

# 添加监听器规则
resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
