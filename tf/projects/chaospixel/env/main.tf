data "aws_caller_identity" "current" {}
locals {
  lambda_service_name = "sc-chaospixel-v1-${var.env}-gql"
  kinesis_worker_lambda_service_name = "sc-chaospixel-v1-${var.env}-kinesis-worker"
  service_name = "chaospixel-v1"
  cloud_front_subdomain = "chaospixel-v1-${var.env}"
}
resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "chaospixel-${var.env}-${var.region}"
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = {
    env = "${var.env}"
  }
}

resource "aws_s3_bucket" "chaospixel_storage_bucket" {
  bucket = "chaospixel-worker-v1-${var.env}-${var.region}"
}




resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls" {
  bucket = aws_s3_bucket.chaospixel_storage_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}
resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.chaospixel_storage_bucket.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_ownership_controls]
}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${local.service_name}-${var.env}-${var.region}-cloudfront-policy"
  description                       = "${local.service_name}-${var.env}-${var.region}-cloudfront-policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.chaospixel_storage_bucket.id

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
        "Resource": "${aws_s3_bucket.chaospixel_storage_bucket.arn}/*"
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
  bucket = aws_s3_bucket.chaospixel_storage_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}
resource "aws_cloudfront_public_key" "cloudfront_public_key" {
  comment     = "${local.service_name}-${var.env}-${var.region}-public-key"
  # encoded_key = var.secrets.chaospixel_cloudfront_pem
  encoded_key = tls_private_key.keypair.public_key_pem
  name        = "${local.service_name}-${var.env}-${var.region}-public-key"
}
resource "aws_cloudfront_key_group" "cloudfront_key_group" {
  comment ="${local.service_name}-${var.env}-${var.region}-keygroup"
  items   = [aws_cloudfront_public_key.cloudfront_public_key.id]
  name    = "${local.service_name}-${var.env}-${var.region}-keygroup"
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.chaospixel_storage_bucket.bucket_regional_domain_name
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









resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_service.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}/*/*/*"
}

resource "aws_s3_bucket_cors_configuration" "chaospixel_storage_bucket" {
  bucket = aws_s3_bucket.chaospixel_storage_bucket.bucket

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
/*resource "aws_secretsmanager_secret" "lambda_secret" {
  name = local.lambda_service_name
}
resource "aws_secretsmanager_secret_version" "lambda_secret_version" {
  secret_id     = aws_secretsmanager_secret.lambda_secret.id
  secret_string = jsonencode({
    DB_ENV = "value1"
  })
}*/
module "lambda_service" {
  service_name = local.lambda_service_name
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
/*  api_gateway_id = var.api_gateway_id
  api_gateway_parent_id = var.api_gateway_base_path_mapping
  api_gateway_stage_id = var.api_gateway_stage_id
  service_uri = "chaospixel"*/
  lambda_memory_size = 512
  env_vars =  {
    ENV: var.env,
    DB_URL: var.secrets.chaospixel_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN: aws_kinesis_stream.kinesis_stream.arn
    AWS_BATCH_JOB_QUEUE: module.chaospixel_batch_worker.batch_job_queue.arn
    CLOUD_FRONT_DOMAIN: "${local.cloud_front_subdomain}.${var.hosted_zone_name}" #  aws_cloudfront_distribution.s3_distribution.domain_name
    CLOUD_FRONT_PEM: tls_private_key.keypair.private_key_pem
    CLOUD_FRONT_PUBLIC_KEY_ID: aws_cloudfront_public_key.cloudfront_public_key.id
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    STRIPE_PRODUCT_PRICE_ID: var.secrets.chaospixel_lambda_service_STRIPE_PRODUCT_PRICE_ID,
    DISCORD_APP_ID: var.secrets.chaospixel_lambda_service_DISCORD_APP_ID,
    DISCORD_PUBLIC_KEY: var.secrets.chaospixel_lambda_service_DISCORD_PUBLIC_KEY,
    DISCORD_TOKEN: var.secrets.chaospixel_lambda_service_DISCORD_TOKEN,
    FIRST_PROMOTER_API_KEY: var.secrets.chaospixel_lambda_service_FIRST_PROMOTER_API_KEY
  }
}

module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "chaospixel-v1"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "chaos-ville"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "lambda/buildspec.yml"
  env_vars =  {
    // ENV: var.env,
    AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    DB_URL: var.secrets.chaospixel_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    AWS_BATCH_JOB_DEFINITION: module.chaospixel_batch_worker.batch_job_definition.arn
    AWS_BATCH_JOB_QUEUE: module.chaospixel_batch_worker.batch_job_queue.arn
    AWS_KINESIS_STREAM_ARN = aws_kinesis_stream.kinesis_stream.arn
    CLOUD_FRONT_DOMAIN: "${local.cloud_front_subdomain}.${var.hosted_zone_name}"  #  aws_cloudfront_distribution.s3_distribution.domain_name
    CLOUD_FRONT_PEM: tls_private_key.keypair.private_key_pem
    CLOUD_FRONT_PUBLIC_KEY_ID: aws_cloudfront_public_key.cloudfront_public_key.id
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    STRIPE_PRODUCT_PRICE_ID: var.secrets.chaospixel_lambda_service_STRIPE_PRODUCT_PRICE_ID,
    DISCORD_APP_ID: var.secrets.chaospixel_lambda_service_DISCORD_APP_ID,
    DISCORD_PUBLIC_KEY: var.secrets.chaospixel_lambda_service_DISCORD_PUBLIC_KEY,
    DISCORD_TOKEN: var.secrets.chaospixel_lambda_service_DISCORD_TOKEN,
    FIRST_PROMOTER_API_KEY: var.secrets.chaospixel_lambda_service_FIRST_PROMOTER_API_KEY
  }
}

resource "aws_iam_policy" "codebuild_iam_policy" {
  name = "chaospixel-v1-${var.env}-codebuild"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "LambdaDeploy",
          "Effect": "Allow",
          "Action": [
            "lambda:GetFunction",
            "lambda:UpdateFunctionCode",
            "lambda:UpdateFunctionConfiguration"
          ],
          "Resource": [
            module.lambda_service.lambda_function.arn,
            module.kinesis_worker_lambda_service.lambda_function.arn
          ]
        }
      ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "codebuild_iam_policy_attach" {
  role = module.buildpipeline.code_build_iam_role.name
  policy_arn = aws_iam_policy.codebuild_iam_policy.arn
}



resource "aws_iam_policy" "lambda_iam_policy" {
  name = "chaospixel-v1-${var.env}-lambda"

  policy = jsonencode(
   {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
          ],
          Resource : "*",
        },
        {
          Effect : "Allow",
          Action : ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
          Resource : ["*"],
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_service_name}-*",
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_service_name}-*:*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "batch:SubmitJob"
          ],
          "Resource" : [
            "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/chaospixel-worker-v1-${var.env}-${var.env}:*"
            // TODO: Import Job Queue `chaospixel-worker-v1-\${AWS::Region}-\${opt:stage, "test"}-JobQueue`
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "batch:DescribeJobs"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          "Resource" : [
            aws_s3_bucket.chaospixel_storage_bucket.arn,
            "${aws_s3_bucket.chaospixel_storage_bucket.arn}/**"
          ]
        },
        {
          Effect : "Allow",
          Action : [
            "kinesis:PutRecord",
            "kinesis:PutRecords",
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream",
            "kinesis:ListShards",
            "kinesis:ListStreams",
          ],
          Resource : aws_kinesis_stream.kinesis_stream.arn,
        },
        {
          Effect : "Allow",
          Action : [
            "batch:SubmitJob"
          ],
          Resource : [
            module.chaospixel_batch_worker.batch_job_queue.arn,
            "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/${module.chaospixel_batch_worker.batch_job_definition.name}:*"
          ]
        },
        {
          Effect : "Allow",
          Action : [
            "ses:SendEmail",
            "ses:SendRawEmail"
          ],
          Resource : [
            "*"
          ]
        }
      ]
    }

  )
}
resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attach" {
  role = module.lambda_service.iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
resource "aws_iam_role_policy_attachment" "lambda_iam_xray_policy_attach" {
  role = module.lambda_service.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}



module "kinesis_worker_lambda_service" {
  service_name = local.kinesis_worker_lambda_service_name
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  handler = "src/functions/kinesis-worker/handler.main"
  lambda_memory_size = 512
  env_vars =  {
    ENV: var.env,
    DB_URL: var.secrets.chaospixel_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = aws_kinesis_stream.kinesis_stream.arn
    AWS_BATCH_JOB_DEFINITION = module.chaospixel_batch_worker.batch_job_definition.arn
    AWS_BATCH_JOB_QUEUE = module.chaospixel_batch_worker.batch_job_queue.arn
    CLOUD_FRONT_DOMAIN: aws_cloudfront_distribution.s3_distribution.domain_name
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    STRIPE_PRODUCT_PRICE_ID: var.secrets.chaospixel_lambda_service_STRIPE_PRODUCT_PRICE_ID
    FIRST_PROMOTER_API_KEY: var.secrets.chaospixel_lambda_service_FIRST_PROMOTER_API_KEY
  }
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = aws_kinesis_stream.kinesis_stream.arn
  function_name     = module.kinesis_worker_lambda_service.lambda_function.arn
  starting_position = "LATEST"
  maximum_retry_attempts = 1
}

resource "aws_iam_role_policy_attachment" "kinesis_worker_lambda_iam_policy_attach" {
  role = module.kinesis_worker_lambda_service.iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
resource "aws_iam_role_policy_attachment" "batch_worker_lambda_iam_policy_attach" {
  role = module.chaospixel_batch_worker.batch_job_definition_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
module "chaospixel_batch_worker" {
  service_name = "chaospixel-worker"
  source = "../../../../modules/aws-batch-pytorch-gpu-service"
  region = "us-east-1"
  env = var.env
  vpc_id = var.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  output_bucket                      = aws_s3_bucket.chaospixel_storage_bucket
  bastion_security_group = var.bastion_security_group

  codepipeline_github_owner = "schematical"
  codepipeline_github_project_name = "chaospixel-batch-worker"
  codepipeline_github_source_branch = var.env
  codepipeline_source_buildspec_path = "buildspec.yml"

}




