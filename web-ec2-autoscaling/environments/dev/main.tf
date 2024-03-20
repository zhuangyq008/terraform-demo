provider "aws" {
  region = local.region
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
  backend "s3" {
    bucket = "us-east-1-poc-demo"
    key    = "web-server-autoscaling-tf"
    region = "us-east-1"
  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_ami" "base" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  most_recent = true
}

locals {
  name = var.cluster_name
  # name = basename(path.cwd)
  # var.cluster_name is for Terratest
  # cluster_name = coalesce(var.cluster_name, local.name)
  cluster_name = var.cluster_name
  region       = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Blueprint  = local.name
    Project = "devax-three-tier"
    Environment = "Dev"
  }
}

#---------------------------------------------------------------
# Foundation for the deployment
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = false

  # # redis
  # create_elasticache_subnet_group = true
  # elasticache_subnet_group_name   = "redis-subnet"
  # elasticache_subnets             = ["10.0.50.0/24"]

  # # database
  # database_subnets                = ["10.0.60.0/24", "10.0.61.0/24", "10.0.62.0/24"]
  # database_subnet_group_name      = "database-subnet"

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "Name" = "${local.cluster_name}-public"
  }

  private_subnet_tags = {
    "Name" = "${local.cluster_name}-private"
  }

  tags = local.tags
}

resource "aws_security_group" "terramino_instance" {
  name = "learn-asg-terramino-instance"
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.terramino_lb.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.terramino_lb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "terramino_lb" {
  name = "learn-asg-terramino-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

module application {
  source             = "../../application"
  vpc_id             = module.vpc.vpc_id
  vpc_zone_identifier = module.vpc.private_subnets
  public_subnets     = module.vpc.public_subnets
  vpc_security_group_ids = [aws_security_group.terramino_instance.id]
  lb_security_groups    = [aws_security_group.terramino_lb.id]
  app_ami = data.aws_ami.base.id
}

# module database {
#   source             = "./database"
#   vpc_id             = module.vpc.vpc_id
#   redis_subnet_group_name  = module.vpc.elasticache_subnet_group_name
#   database_subnets   = module.vpc.database_subnets
# }


# resource "aws_s3_bucket" "frontend_static_website" {
#   bucket = "devax-eshop-frontend-enginez2"
#   force_destroy = true
# }