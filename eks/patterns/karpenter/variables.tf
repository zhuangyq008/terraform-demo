variable "vpc_id" {
  type = string
  default = "vpc-0533d70a4f51d42c7"
}
variable "private_subnets" {
  type = list(string)
  default = ["subnet-054e5b07bcd50597a","subnet-0e1adeca24ec963bb"]
}