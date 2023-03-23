provider "aws" {
  region = local.region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name = var.cluster_name
  # name = basename(path.cwd)
  # var.cluster_name is for Terratest
  # cluster_name = coalesce(var.cluster_name, local.name)
  cluster_name = var.cluster_name
  region       = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    Project = "devax-three-tier"
  }
}

#---------------------------------------------------------------
# Foundation for the deployment
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # redis
  create_elasticache_subnet_group = true
  elasticache_subnet_group_name   = "redis-subnet"
  elasticache_subnets             = ["10.0.50.0/24"]

  # database
  database_subnets                = ["10.0.60.0/24", "10.0.61.0/24", "10.0.62.0/24"]
  database_subnet_group_name      = "database-subnet"

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}

module application {
  source             = "./application"
  vpc_id             = module.vpc.vpc_id
  vpc_zone_identifier = module.vpc.private_subnets
  public_subnets     = module.vpc.public_subnets
  vpc_security_group_ids = [aws_security_group.terramino_instance.id]
  lb_security_groups    = [aws_security_group.terramino_lb.id]
}

module database {
  source             = "./database"
  vpc_id             = module.vpc.vpc_id
  redis_subnet_group_name  = module.vpc.elasticache_subnet_group_name
  database_subnets   = module.vpc.database_subnets
}


resource "aws_s3_bucket" "frontend_static_website" {
  bucket = "devax-eshop-frontend-enginez2"
  force_destroy = true
}