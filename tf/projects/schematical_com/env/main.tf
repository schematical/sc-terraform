
module "cloudfront" {
  service_name = "schematical-com-v1"
  source = "../../../../modules/cloudfront"
  region = var.region
  env = var.env
  subdomain = "assets-${var.env}"
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  api_gateway_id = var.api_gateway_id
  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  cors_allowed_hosts = [
    "${var.domain_name}.${var.hosted_zone_name}",
    var.hosted_zone_name
  ]
}


data "aws_caller_identity" "current" {}
module "lambda_service" {
  service_name = "schematical-com-v1-${var.env}-www"
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  env_vars = {
    REACT_APP_SERVER_URL:  "https://${var.domain_name}.${var.hosted_zone_name}"
    AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
  }
/*  api_gateway_id = var.api_gateway_id
  api_gateway_parent_id = var.api_gateway_base_path_mapping
  api_gateway_stage_id = module.dev_env.api_gateway_stage_id
  service_uri = "chaospixel"*/
  layers = [
    // aws_lambda_layer_version.asset_lambda_layer.arn,
    // aws_lambda_layer_version.dependency_lambda_layer.arn,
    // aws_lambda_layer_version.code_lambda_layer.arn,
  ]
/*
  use_s3_source = true
  s3_bucket = var.codepipeline_artifact_store_bucket.bucket
  s3_key = "schematical-com-v1-${var.env}/code.zip"
*/
  handler = "handler.main"

}

resource "aws_iam_policy" "lambda_iam_policy" {
  name = "schematical-com-v1-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "DynamoDB",
          "Effect": "Allow",
          "Action": [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource": [
            var.dynamodb_table_post_arn
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
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_service.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}/*/*/*"
}

/*resource "aws_lambda_layer_version" "asset_lambda_layer" {
  s3_bucket = var.codepipeline_artifact_store_bucket.bucket
  s3_key = "schematical-com-v1-${var.env}/assetsLayer.zip"
  layer_name = "asset_lambda_layer"

  compatible_runtimes = ["nodejs16.x"]
}
resource "aws_lambda_layer_version" "code_lambda_layer" {
  s3_bucket = var.codepipeline_artifact_store_bucket.bucket
  s3_key = "schematical-com-v1-${var.env}/code.zip"
  layer_name = "code_lambda_layer"

  compatible_runtimes = ["nodejs16.x"]
}
resource "aws_lambda_layer_version" "dependency_lambda_layer" {
  s3_bucket = var.codepipeline_artifact_store_bucket.bucket
  s3_key = "schematical-com-v1-${var.env}/dependenciesLayer.zip"
  layer_name = "dependency_lambda_layer"

  compatible_runtimes = ["nodejs16.x"]
}*/
module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = "schematical-com-v1"
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "schematical-com"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "buildspec.yml"
  env_vars = {
    REACT_APP_SERVER_URL:  "https://${var.domain_name}.${var.hosted_zone_name}"
    AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
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
}
resource "aws_iam_policy" "codebuild_iam_policy" {
  name = "schematical-com-v1-${var.env}-codebuild"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "LambdaDeploy",
          "Effect": "Allow",
          "Action": [
            "lambda:UpdateFunctionCode",
            "lambda:GetFunction",
            "lambda:UpdateFunctionConfiguration"
          ],
          "Resource": [
            module.lambda_service.lambda_function.arn
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
            "s3:PutObjectAcl",
            "s3:*"
          ]
          Resource = [
            "${module.cloudfront.s3_bucket.arn}/**",
            "${module.cloudfront.s3_bucket.arn}"
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
module "apigateway_env" {

  source = "../../../../modules/apigateway-env"
  env = var.env
  // vpc_id = var.vpc_id
  // ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = var.api_gateway_id
  hosted_zone_id = var.hosted_zone_id
  hosted_zone_name = var.hosted_zone_name
  acm_cert_arn = var.acm_cert_arn
  domain_name = var.domain_name
  // private_subnet_mappings = var.private_subnet_mappings
}

