output "cloudfront_dn" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "The cloudfront domain name"
}