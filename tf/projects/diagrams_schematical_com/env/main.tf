locals {
  cloud_front_subdomain = "diagrams-v1-${var.env}.diagrams"
}
module "nextjs_lambda" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../../modules/nextjs-lambda-frontend-env"
  env = var.env
  service_name = "${var.service_name}"
  vpc_id = var.vpc_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  private_subnet_mappings = var.private_subnet_mappings
  acm_cert_arn = var.acm_cert_arn
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = var.api_gateway_base_path_mapping
  subdomain = var.subdomain
  cloudfront_subdomain = "${var.env}-assets.diagrams"
  secrets = var.secrets
  github_owner = "schematical"
  github_project_name = "sc-diagrams"
  source_buildspec_path = "www/buildspec.yml"
  extra_env_vars = {
    NEXT_PUBLIC_GRAPHQL_URI: "https://${var.env}-v1-${var.region}-api.schematical.com/chaoscrawler",
    S3_BUCKET: aws_s3_bucket.diagrams_s3_bucket.bucket,
    PUBLIC_UPLOAD_BUCKET_URL: "https://${aws_route53_record.drawnby-ai-cloudfront-domain.name}",
  }
}


resource "aws_s3_bucket" "diagrams_s3_bucket" {
  # Add your bucket configuration here
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls" {
  bucket = aws_s3_bucket.diagrams_s3_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}
resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.diagrams_s3_bucket.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_ownership_controls]
}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.service_name}-uploads-${var.env}-${var.region}-cloudfront-policy"
  description                       = "${var.service_name}-uploads-${var.env}-${var.region}-cloudfront-policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.diagrams_s3_bucket.id

  policy = jsonencode({
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
      {
        "Sid": "1",
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudfront.amazonaws.com" # "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_control.default.id}"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.diagrams_s3_bucket.arn}/*"
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })#
}


resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.diagrams_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}
resource "aws_cloudfront_public_key" "cloudfront_public_key" {
  comment     = "${var.service_name}-uploads-${var.env}-${var.region}-public-key"
  # encoded_key = var.secrets.chaospixel_cloudfront_pem
  encoded_key = tls_private_key.keypair.public_key_pem
  name        = "${var.service_name}-uploads-${var.env}-${var.region}-public-key"
}
resource "aws_cloudfront_key_group" "cloudfront_key_group" {
  comment ="${var.service_name}-uploads-${var.env}-${var.region}-keygroup"
  items   = [aws_cloudfront_public_key.cloudfront_public_key.id]
  name    = "${var.service_name}-uploads-${var.env}-${var.region}-keygroup"
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.diagrams_s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  /*
    logging_config {
      include_cookies = false
      bucket          = "mylogs.s3.amazonaws.com"
      prefix          = "myprefix"
    }
  */

  aliases = [  "${local.cloud_front_subdomain}.${var.hosted_zone_name}" ]

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
    /*  trusted_key_groups = [
        aws_cloudfront_key_group.cloudfront_key_group.id
      ]*/
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    env = var.env,
    region = var.region,
    Service = "chaospixel-v1"
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_cert_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
resource "aws_route53_record" "drawnby-ai-cloudfront-domain" {
  zone_id = var.hosted_zone_id
  name    = local.cloud_front_subdomain
  type    = "A"
  # ttl     = "30"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  }
  /*  records = [
  aws_cloudfront_distribution.s3_distribution.domain_name
    ]*/
}
