

locals {
  cloudfront_subdomain = "assets-${var.env}"
}
/*module "cloudfront" {
  service_name = var.service_name
  source = "../../../../modules/cloudfront"
  region = var.region
  env = var.env
  subdomain = local.cloudfront_subdomain
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  cors_allowed_hosts = [
    "localhost",
    "localhost:3000",
    "${var.subdomain}.${var.hosted_zone_name}",
    "www.${var.hosted_zone_name}",
    var.hosted_zone_name
  ]
}
resource "aws_s3_bucket_cors_configuration" "chaospixel_storage_bucket" {
  bucket = module.cloudfront.s3_bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"] ## https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  bucket = module.cloudfront.s3_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "S3"
        Effect    = "Allow"
        Principal = "*" // aws_iam_policy.codebuild_iam_policy.arn
        Action    = "s3:*"
        Resource  = module.cloudfront.s3_bucket.arn

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}*/
