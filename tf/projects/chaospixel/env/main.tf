data "aws_caller_identity" "current" {}
locals {
  lambda_service_name = "sc-chaospixel-v1-${var.env}-gql"
  kinesis_worker_lambda_service_name = "sc-chaospixel-v1-${var.env}-kinesis-worker"
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

resource "aws_s3_bucket" "dreambooth_storage_bucket" {
  bucket = "dreambooth-worker-v1-${var.env}-${var.region}"
}



resource "aws_s3_bucket_cors_configuration" "dreambooth_storage_bucket" {
  bucket = aws_s3_bucket.dreambooth_storage_bucket.bucket

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
  env_vars =  {
    ENV: var.env,
    DB_URL: var.secrets.chaospixel_dev_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_dev_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_dev_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = aws_kinesis_stream.kinesis_stream.arn
  }//jsondecode(aws_secretsmanager_secret_version.lambda_secret_version.secret_string)
}
resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = var.api_gateway_id # aws_api_gateway_rest_api.MyDemoAPI.id
  parent_id   = var.api_gateway_base_path_mapping # aws_api_gateway_rest_api.MyDemoAPI.root_resource_id
  path_part   = "chaospixel"
}
resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "ANY"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_gateway_root_resource_method_integration" {
  rest_api_id          = var.api_gateway_id
  resource_id          = aws_api_gateway_resource.api_gateway_resource.id
  http_method          = aws_api_gateway_method.api_gateway_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  // passthrough_behavior    = "WHEN_NO_MATCH"
  // content_handling        = "CONVERT_TO_BINARY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:sc-chaospixel-v1-$${stageVariables.ENV}-gql/invocations"
}
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_service.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}/*/*/*"
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
    AUTH_CLIENT_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_USER_POOL_ID
    DB_URL: var.secrets.chaospixel_dev_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_dev_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_dev_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = aws_kinesis_stream.kinesis_stream.arn
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
            "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/dreambooth-worker-v1-${var.env}-${var.env}:*"
            // TODO: Import Job Queue `dreambooth-worker-v1-\${AWS::Region}-\${opt:stage, "test"}-JobQueue`
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:getObject",
            "s3:putObject"
          ],
          "Resource" : [
            aws_s3_bucket.dreambooth_storage_bucket.arn
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
            module.dreambooth_batch_worker.batch_job_queue.arn,
            module.dreambooth_batch_worker.batch_job_definition.arn
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



module "kinesis_worker_lambda_service" {
  service_name = local.kinesis_worker_lambda_service_name
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  handler = "src/functions/kinesis-worker/handler.main"
  env_vars =  {
    ENV: var.env,
    DB_URL: var.secrets.chaospixel_dev_lambda_service_DB_URL
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_CLIENT_ID
    AUTH_USER_POOL_ID: var.secrets.chaospixel_dev_lambda_service_AUTH_USER_POOL_ID
    AWS_S3_BUCKET: var.secrets.chaospixel_dev_lambda_service_AWS_S3_BUCKET
    OPENAI_API_KEY: var.secrets.chaospixel_dev_lambda_service_OPENAI_API_KEY
    AWS_KINESIS_STREAM_ARN = aws_kinesis_stream.kinesis_stream.arn
    AWS_BATCH_TRAINING_JOB_DEFINITION = module.dreambooth_batch_worker.batch_job_definition.arn
    AWS_BATCH_JOB_QUEUE = module.dreambooth_batch_worker.batch_job_queue.arn
  }//jsondecode(aws_secretsmanager_secret_version.lambda_secret_version.secret_string)
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

module "dreambooth_batch_worker" {
  service_name = "dreambooth"
  source = "../../../../modules/aws-batch-pytorch-gpu-service"
  region = "us-east-1"
  env = var.env
  vpc_id = var.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  output_bucket                      = aws_s3_bucket.dreambooth_storage_bucket
  bastion_security_group = var.bastion_security_group

  codepipeline_github_owner = "schematical"
  codepipeline_github_project_name = "chaos-ville"
  codepipeline_github_source_branch = var.env
  codepipeline_source_buildspec_path = "batch/buildspec.yml"

}




