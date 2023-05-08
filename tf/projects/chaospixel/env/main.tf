

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

module "lambda_service" {
  service_name = var.project_name
  source = "../../../../modules/lambda-service"
  region = var.region
  env = var.env
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  api_gateway_id = var.api_gateway_id
  api_gateway_parent_id = var.api_gateway_base_path_mapping
  api_gateway_stage_id = var.api_gateway_stage_id
  service_uri = "/chaospixel"
}
module "buildpipeline" {
  source = "../../../../modules/buildpipeline"# "github.com/schematical/sc-terraform/modules/buildpipeline"
  service_name = var.project_name
  region = var.region
  env = var.env
  github_owner = "schematical"
  github_project_name = "chaos-ville"
  github_source_branch = var.env
  code_pipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  private_subnet_mappings = var.private_subnet_mappings
  source_buildspec_path = "modules/aws-batch-pytorch-gpu-service/build/buildspec.yml"
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
}





/*module "sagemaker_endpoint" {
  source = "../sagemaker"
  region = "us-east-1"
  env = var.env

  code_pipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

}*/

/*module "sagemaker_serverless" {
  source = "../sagemaker-serverless"
  region = "us-east-1"
  env = var.env

  code_pipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket.bucket
  vpc_id = var.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

}*/