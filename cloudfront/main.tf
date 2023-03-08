
#see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
# bucket替换您的桶
resource "aws_s3_bucket" "b" {
  bucket = "poc-website-enginez"
  acl = "private"

  tags = {
    Name = "terraform web poc bucket"
  }
}
# 日志bucket替换您的桶
resource "aws_s3_bucket" "logbucket" {
  bucket = "poc-engine-logmain"

  tags = {
    Name = "terraform web poc bucket"
  }
}
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "terraform example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terraform example comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "poc-engine-logmain.s3.amazonaws.com"
    prefix          = "cloudfront-log/"
  }

  #aliases = ["engineweb.aws.icloud2022.cn"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_200"

#  配置地理位置限制
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      #https://www.iso.org/obp/ui/#iso:pub:PUB500001:en
      locations        = ["SG","KR","US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
 #To add an alternate domain name (CNAME) to a CloudFront distribution, you must attach a trusted certificate that validates your authorization to use the domain name. For more details, 
 #see: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html#alternate-domain-names-requirements   
 # 
    cloudfront_default_certificate = true
  }
}
resource "aws_s3_bucket_policy" "example_bucket_policy" {
  bucket = "${aws_s3_bucket.b.bucket}"

  policy = <<EOF
{
        "Version": "2008-10-17",
        "Id": "PolicyForCloudFrontPrivateContent",
        "Statement": [
            {
                "Sid": "AllowCloudFrontServicePrincipal",
                "Effect": "Allow",
                "Principal": {
                    "Service": "cloudfront.amazonaws.com"
                },
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                    }
                }
            }
        ]
      }
EOF
}





