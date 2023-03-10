

variable "cluster_size" {
  type        = number
  default = 2
  description = "The cluster size that same size as available_zones"
}
variable "app_version" {
  type = string
  default = "1.0"
}
variable "vpcid" {
  type        = string
  default = "vpc-034cff70368626c7c"
  description = "Please input your vpc_id"
}

variable "subnetIds" {
  type = list(string)
  default = ["subnet-01625e7de23684706","subnet-060a930278e61d663"]
  description = "Please input your subnets,at least two"
}
variable "securityGroups" {
  type = list(string)
  default = ["sg-0203a1a98ff22267f"]
  description = "Please input security group ids"
}
variable "image_id" {
  type        = string
  default = "ami-094bbd9e922dc515d"
  description = "The AMI id"
}

variable "key_name" {
  type        = string
  default = "my-kp-default"
  description = "the ssh keypair for remote connection"
}

variable "instance_type" {
  type        = string
  default = "t3.medium"
  description = "The EC2 instance type"
}


