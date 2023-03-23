variable "vpc_id" {
  
}
variable "vpc_zone_identifier" {
  
}
variable "vpc_security_group_ids" {
  
}
variable "lb_security_groups" {
  
}
variable "public_subnets" {
  
}
variable "app_ami" {
    # region ap-southeast-1
    default = "ami-094bbd9e922dc515d"
    description = "The AMI id"
}
variable "app_inst_type" {
    default = "t2.micro"
    description = "The EC2 Instance Spec"
}

variable "key_name" {
  type        = string
  default = "my-kp-default"
  description = "the ssh keypair for remote connection"
}