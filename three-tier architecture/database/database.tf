locals {
  maindb_mysql_name = "devax-demo"
}

resource "aws_security_group" "redis-sg" {
  name        = "allow_redis"
  description = "Allow redis inbound/outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow ingress"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    # Name = "llow redis inbound/outbound traffic"
    Name = "devax-sg-redis"

  }
}

resource "aws_elasticache_cluster" "devax-demo" {
  cluster_id           = var.cluster_name
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  # parameter_group_name = var.parameter_group_name
  engine_version       = var.engine_version
  port                 = 6379
  security_group_ids   = [aws_security_group.redis-sg.id]
  subnet_group_name    = var.redis_subnet_group_name

}


module "aurora-cluster" {
  source  = "terraform-aws-modules/rds-aurora/aws"

  name              = local.maindb_mysql_name
  engine            = "aurora-mysql"
  engine_mode       = "provisioned"
  engine_version    = "8.0.mysql_aurora.3.02.1"

  vpc_id         = var.vpc_id
  subnets        = var.database_subnets

  create_security_group = true
  # allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks
  allowed_cidr_blocks     = ["0.0.0.0/0"]

  storage_encrypted   = true
  apply_immediately   = true
  skip_final_snapshot = true
  monitoring_interval = 60

  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 10
  }
  instance_class = "db.serverless"
  instances = {
    one = {}
  }
  master_username     = "admin"
  master_password     = random_password.mysql_password.result

  # enabled_cloudwatch_logs_exports = ["postgresql"]
  db_parameter_group_name         = aws_db_parameter_group.maindb_mysql8.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.maindb_mysql8.id

  tags = {
    # Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_db_parameter_group" "maindb_mysql8" {
  name        = "${local.maindb_mysql_name}-aurora-db-mysql8-parameter-group"
  family      = "aurora-mysql8.0"
  description = "${local.maindb_mysql_name}-aurora-db-mysql8-parameter-group"
  # tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "maindb_mysql8" {
  name        = "${local.maindb_mysql_name}-aurora-mysql8-cluster-parameter-group"
  family      = "aurora-mysql8.0"
  description = "${local.maindb_mysql_name}-aurora-mysql8-cluster-parameter-group"
  # tags        = local.tags
}

resource "random_password" "mysql_password" {
  length           = 16
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "aws_secretsmanager_secret" "maindb_mysql_master_user" {
  name        = "maindb_mysql_master_user"
  description = "maindb_mysql_master_user"
  recovery_window_in_days = 0
  # tags = {
  #   Name        = "service_user"
  #   Environment = var.app_environment
  # }
}

resource "aws_secretsmanager_secret_version" "maindb_mysql_master_pwd" {
  secret_id     = aws_secretsmanager_secret.maindb_mysql_master_user.id
  secret_string = random_password.mysql_password.result
}