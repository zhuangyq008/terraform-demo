# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "4.37.0"
#     }
#   }
# }

provider "aws" {
  region     = "ap-southeast-1"
}

module "init_s3origin" {
  source                        = "./s3origin/"
  origin-s3-bucket              = "mys3-${formatdate("YYYY-MM-DDhhmmss", timestamp())}"
  cloudfront-logging-bucket     = "cloudfront-logging-${formatdate("YYYY-MM-DDhhmmss", timestamp())}"
}