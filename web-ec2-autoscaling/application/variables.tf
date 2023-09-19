variable "vpc_id" {
  
}
variable "vpc_zone_identifier" {
  
}
variable "ec2_tags" {
  
}
variable "vpc_security_group_ids" {
  
}
variable "lb_security_groups" {
  
}
variable "public_subnets" {
  
}

variable "app_inst_type" {
    default = "t2.micro"
    description = "The EC2 Instance Spec"
}
variable "app_ami" {
    type = string
    description = "The EC2 AMI"
}
variable "key_name" {
  type        = string
  default = "us-west-2-kp"
  description = "the ssh keypair for remote connection"
}