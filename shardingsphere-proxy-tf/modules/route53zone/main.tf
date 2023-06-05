resource "aws_route53_zone" "private_zone" {
  name = "shardingsphere.org"
  vpc {
    vpc_id = "${var.vpc_id}"
  }
}