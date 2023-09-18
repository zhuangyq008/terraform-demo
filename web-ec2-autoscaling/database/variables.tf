variable "node_type" {
  default = "cache.t3.small"
}

variable "cluster_name" {
  default = "devax-demo"
}

variable "engine_version" {
  default = "7.0"
}

# variable "parameter_group_name" { 
#   default = "default.redis6.2"
# }

# variable "security_group_ids" {
#   type = list(string)
# }


variable "vpc_id" {
  
}

variable "redis_subnet_group_name" {
  
}

variable "database_subnets" {
  type = list(string)
}