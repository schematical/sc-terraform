
data "aws_caller_identity" "current" {}

locals {
  lambda_service_name = "chaoscrawler-v1-${var.env}-gql"
  kinesis_worker_lambda_service_name = "chaoscrawler-v1-${var.env}-kinesis-worker"
  ses_worker_lambda_service_name = "chaoscrawler-v1-${var.env}-ses-worker"
  service_name = "chaoscrawler-v1"
  cloud_front_subdomain = "chaoscrawler-v1-${var.env}"
  ses_domain = var.env == "prod" ? "chaoscrawler.schematical.com" : "${var.env}-chaoscrawler.schematical.com"
}


resource "aws_s3_bucket" "chaoscrawler_storage_bucket" {
  bucket = "chaoscrawler-worker-v1-${var.env}-${var.region}"
}




resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls" {
  bucket = aws_s3_bucket.chaoscrawler_storage_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}
resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.chaoscrawler_storage_bucket.id
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
  bucket = aws_s3_bucket.chaoscrawler_storage_bucket.id

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
        "Resource": "${aws_s3_bucket.chaoscrawler_storage_bucket.arn}/*"
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
  bucket = aws_s3_bucket.chaoscrawler_storage_bucket.id

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
  # encoded_key = var.secrets.chaoscrawler_cloudfront_pem
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
    domain_name              = aws_s3_bucket.chaoscrawler_storage_bucket.bucket_regional_domain_name
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
    Service = "chaoscrawler-v1"
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

resource "aws_s3_bucket_cors_configuration" "chaoscrawler_storage_bucket" {
  bucket = aws_s3_bucket.chaoscrawler_storage_bucket.bucket

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



locals {
  zip_file = "${path.module}/index.zip"
}
data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "/mnt/d/WebstormProjects/chaoscrawler/lambda_layer"
  output_path = local.zip_file
}
resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = data.archive_file.lambda.output_path
  layer_name = "${local.lambda_service_name}-${var.env}-${var.region}"

  compatible_runtimes = ["nodejs16.x"]
}
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
    service_uri = "chaoscrawler"*/
  layers = [
    "arn:aws:lambda:${var.region}:764866452798:layer:chrome-aws-lambda:45",
    aws_lambda_layer_version.lambda_layer.arn,
  ]
  lambda_memory_size = 1028
  env_vars =  {
    NODE_ENV: var.env,
    ENV: var.env,
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN: var.kinesis_stream_arn
    CLOUD_FRONT_DOMAIN: "${local.cloud_front_subdomain}.${var.hosted_zone_name}" #  aws_cloudfront_distribution.s3_distribution.domain_name
    CLOUD_FRONT_PEM: tls_private_key.keypair.private_key_pem
    CLOUD_FRONT_PUBLIC_KEY_ID: aws_cloudfront_public_key.cloudfront_public_key.id
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    DISCORD_APP_ID: var.secrets.chaospixel_lambda_service_DISCORD_APP_ID,
    DISCORD_PUBLIC_KEY: var.secrets.chaospixel_lambda_service_DISCORD_PUBLIC_KEY,
    DISCORD_TOKEN: var.secrets.chaospixel_lambda_service_DISCORD_TOKEN,
    ELEVEN_LABS_API_KEY: var.secrets.chaoscrawler_lambda_service_ELEVEN_LABS_API_KEY
    AWS_S3_BUCKET: aws_s3_bucket.chaoscrawler_storage_bucket.bucket

  }
}

module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "chaoscrawler-v1"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "chaoscrawler"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "lambda/buildspec.yml"
  env_vars =  {
    // ENV: var.env,
    NODE_ENV: var.env,
    AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = var.kinesis_stream_arn
    CLOUD_FRONT_DOMAIN: "${local.cloud_front_subdomain}.${var.hosted_zone_name}"  #  aws_cloudfront_distribution.s3_distribution.domain_name
    CLOUD_FRONT_PEM: tls_private_key.keypair.private_key_pem
    CLOUD_FRONT_PUBLIC_KEY_ID: aws_cloudfront_public_key.cloudfront_public_key.id
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    DISCORD_APP_ID: var.secrets.chaospixel_lambda_service_DISCORD_APP_ID,
    DISCORD_PUBLIC_KEY: var.secrets.chaospixel_lambda_service_DISCORD_PUBLIC_KEY,
    DISCORD_TOKEN: var.secrets.chaospixel_lambda_service_DISCORD_TOKEN,
    ELEVEN_LABS_API_KEY: var.secrets.chaoscrawler_lambda_service_ELEVEN_LABS_API_KEY
    AWS_S3_BUCKET: aws_s3_bucket.chaoscrawler_storage_bucket.bucket
  }
}

resource "aws_iam_policy" "codebuild_iam_policy" {
  name = "chaoscrawler-v1-${var.env}-codebuild"

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
            module.kinesis_worker_lambda_service.lambda_function.arn,
            module.ses_worker_lambda_service.lambda_function.arn
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
  name = "chaoscrawler-v1-${var.env}-lambda"

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
            "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/chaoscrawler-worker-v1-${var.env}-${var.env}:*"
            // TODO: Import Job Queue `chaoscrawler-worker-v1-\${AWS::Region}-\${opt:stage, "test"}-JobQueue`
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
            aws_s3_bucket.chaoscrawler_storage_bucket.arn,
            "${aws_s3_bucket.chaoscrawler_storage_bucket.arn}/**"
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
          Resource : var.kinesis_stream_arn,
        },
        /*{
          Effect : "Allow",
          Action : [
            "batch:SubmitJob"
          ],
          Resource : [
            module.chaoscrawler_batch_worker.batch_job_queue.arn,
            "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/${module.chaoscrawler_batch_worker.batch_job_definition.name}:*"
          ]
        },*/
        {
          Effect : "Allow",
          Action : [
            "ses:SendEmail",
            "ses:SendRawEmail"
          ],
          Resource : [
            "*"
          ]
        },
        {
          Effect : "Allow",
          Action : [
            "ce:GetCostAndUsage"
          ],
          Resource : [
            "*"
          ]
        },
        {
          "Sid": "DynamoDB",
          "Effect": "Allow",
          "Action": [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:BatchGetItem"
          ],
          "Resource": [
            aws_dynamodb_table.dynamodb_table_user.arn,
            aws_dynamodb_table.dynamodb_table_signupcode.arn,
            aws_dynamodb_table.dynamodb_table_digeststream.arn,
            aws_dynamodb_table.dynamodb_table_digeststreamitem.arn,
            aws_dynamodb_table.dynamodb_table_digeststreamepisode.arn,
            aws_dynamodb_table.dynamodb_table_diagram.arn,
            aws_dynamodb_table.dynamodb_table_diagramobject.arn,
            aws_dynamodb_table.dynamodb_table_diagramflow.arn,
            aws_dynamodb_table.dynamodb_table_site.arn,
            aws_dynamodb_table.dynamodb_table_site_element.arn
          ]
        },
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
  layers = [
    aws_lambda_layer_version.lambda_layer.arn
  ]
  env_vars =  {
    ENV: var.env,
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = var.kinesis_stream_arn
    CLOUD_FRONT_DOMAIN: aws_cloudfront_distribution.s3_distribution.domain_name
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    AWS_S3_BUCKET: aws_s3_bucket.chaoscrawler_storage_bucket.bucket
  }
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = var.kinesis_stream_arn
  function_name     = module.kinesis_worker_lambda_service.lambda_function.arn
  starting_position = "LATEST"
  maximum_retry_attempts = 1
  # https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventfiltering.html
  # filter_criteria =
}

resource "aws_iam_role_policy_attachment" "kinesis_worker_lambda_iam_policy_attach" {
  role = module.kinesis_worker_lambda_service.iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}





module "ses_worker_lambda_service" {
  service_name = local.ses_worker_lambda_service_name
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  handler = "src/functions/ses-worker/handler.main"
  lambda_memory_size = 512
  layers = [
   aws_lambda_layer_version.lambda_layer.arn
  ]
  env_vars =  {
    ENV: var.env,
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
    OPENAI_API_KEY: var.secrets.chaospixel_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = var.kinesis_stream_arn
    CLOUD_FRONT_DOMAIN: aws_cloudfront_distribution.s3_distribution.domain_name
    SENDGRID_API_KEY: var.secrets.chaospixel_lambda_service_SENDGRID_API_KEY
    STRIPE_API_KEY: var.secrets.chaospixel_lambda_service_STRIPE_API_KEY
    AWS_S3_BUCKET: aws_s3_bucket.chaoscrawler_storage_bucket.bucket
  }
}



resource "aws_iam_role_policy_attachment" "ses_worker_lambda_iam_policy_attach" {
  role = module.ses_worker_lambda_service.iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_ses_domain_identity" "ses_domain_identity_chaoscrawler_schematical_com" {
  domain = local.ses_domain
}
resource "aws_route53_record" "route53_record_chaoscrawler_schematical_com" {
  zone_id = var.hosted_zone_id
  name    = local.ses_domain
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.ses_domain_identity_chaoscrawler_schematical_com.verification_token]
}
resource "aws_ses_domain_identity_verification" "example_verification" {
  domain = aws_ses_domain_identity.ses_domain_identity_chaoscrawler_schematical_com.id

  depends_on = [aws_route53_record.route53_record_chaoscrawler_schematical_com]
}

resource "aws_ses_domain_dkim" "ses_domain_dkim_chaoscrawler_schematical_com" {
  domain = aws_ses_domain_identity.ses_domain_identity_chaoscrawler_schematical_com.domain
}
resource "aws_route53_record" "route53_record_mx_chaoscrawler_schematical_com" {
  zone_id = var.hosted_zone_id
  name    = local.ses_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]
}

resource "aws_route53_record" "example_amazonses_dkim_record" {
  count   = 3
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.ses_domain_dkim_chaoscrawler_schematical_com.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.ses_domain_dkim_chaoscrawler_schematical_com.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
resource "aws_ses_receipt_rule" "ses_receipt_rule_chaoscrawler_schematical_com" {
  name          = "chaoscrawler-schematical-com-v1-${var.env}-${var.region}"
  rule_set_name = "default-rule-set"
  recipients    = [local.ses_domain]
  enabled       = true
  scan_enabled  = true

  sns_action {
    position  = 1
    topic_arn = aws_sns_topic.sns_topic.arn
  }


  /*lambda_action {
    invocation_type = "Event"
    function_arn = module.ses_worker_lambda_service.lambda_function.arn
    position     = 1
  }*/
}
resource "aws_sns_topic" "sns_topic" {
  name = "chaoscrawler-v1-${var.env}-${var.region}"
}
/*resource "aws_lambda_permission" "ses_lambda" {
  statement_id  = "AllowExecutionFromSES"
  action        = "lambda:InvokeFunction"
  function_name = module.ses_worker_lambda_service.lambda_function.function_name
  principal     = "ses.amazonaws.com"
  source_arn = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/default-rule-set:receipt-rule/chaoscrawler-schematical-com-v1-${var.env}-${var.region}" // aws_ses_receipt_rule.ses_receipt_rule_chaoscrawler_schematical_com.arn
}*/
resource "aws_lambda_permission" "ses_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.ses_worker_lambda_service.lambda_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn = aws_sns_topic.sns_topic.arn//"arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/default-rule-set:receipt-rule/chaoscrawler-schematical-com-v1-${var.env}-${var.region}" // aws_ses_receipt_rule.ses_receipt_rule_chaoscrawler_schematical_com.arn
}
resource "aws_sns_topic_subscription" "sns-topic" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = module.ses_worker_lambda_service.lambda_function.arn
}
/*

resource "aws_cloudwatch_event_rule" "console" {
  name        = "chaoscrawler-v1-${var.env}-${var.region}"
  description = "Capture each AWS Console Sign In"

  event_pattern = jsonencode({
    detail-type = [
      "AWS Console Sign In via CloudTrail"
    ]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_logins.arn
}*/
