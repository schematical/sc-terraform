
module "lambda_service" {
  service_name = "${var.service_name}-${var.env}-www"
  source = "../lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  env_vars = merge(
    {
      NODE_ENV: var.env
      NEXT_PUBLIC_SERVER_URL:  "https://${var.subdomain}.${var.hosted_zone_name}"
      AUTH_CLIENT_ID: var.secrets.chaospixel_lambda_service_AUTH_CLIENT_ID
      AUTH_USER_POOL_ID: var.secrets.chaospixel_lambda_service_AUTH_USER_POOL_ID
      S3_BUCKET: module.cloudfront.s3_bucket.bucket
      PUBLIC_ASSET_URL: "https://${local.cloudfront_subdomain}.${var.hosted_zone_name}",
      AWS_LAMBDA_EXEC_WRAPPER: "/opt/bootstrap"
      PORT: "8000"
    },
    var.secrets
  )
  layers = [
    "arn:aws:lambda:${var.region}:753240598075:layer:LambdaAdapterLayerX86:20"
  ]
  /*  api_gateway_id = var.api_gateway_id
    api_gateway_parent_id = var.api_gateway_base_path_mapping
    api_gateway_stage_id = module.dev_env.api_gateway_stage_id
    service_uri = "chaospixel"*/
  lambda_runtime = "nodejs18.x"
  handler = "run.sh"
  lambda_timeout = 10
  # image_uri =  "${aws_ecr_repository.ecr_repository.repository_url}:${var.env}"
  # package_type = "Zip" # package_type = "Image"
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name = "${var.service_name}-${var.env}-lambda"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
  /*      {
          "Sid": "DynamoDB",
          "Effect": "Allow",
          "Action": [
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query"
          ],
          "Resource": var.dynamodb_table_arns
        },*/
        {
          "Sid": "s3",
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ],
          "Resource": [
            "${module.cloudfront.s3_bucket.arn}/**"
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