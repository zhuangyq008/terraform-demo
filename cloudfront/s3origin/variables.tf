variable "origin-s3-bucket" {
  type    = string
  description = "please input the origin s3 bucket, the bucket will be created"
  default = "mys3-981293123"
}

variable "cloudfront-logging-bucket" {
  type    = string
  description = "please input the cloudfront logging s3 bucket, the bucket will be created"
  default = "cloudfront-logging-981293123"
}

variable "cloudfront-origin-access-policy" {
  type    = string
  description = "please input the origin access control name, the oac will be created"
  default = "oac-981293123"
}