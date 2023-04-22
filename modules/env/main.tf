
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = var.api_gateway_id
  # depends_on = [aws_api_gateway_stage.api_gateway_stage]
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  stage_name   = var.env
  rest_api_id  = var.api_gateway_id
  variables    = {
    ENV = var.env
  }
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.id
  api_id = var.api_gateway_id
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = var.acm_cert_arn
  domain_name     = "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}"
  endpoint_configuration {
    types = ["EDGE"]
  }
}


resource "aws_route53_record" "route53_record" {
  name = "${var.env}-v1-${var.region}-api.${var.hosted_zone_name}."
  type = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
  zone_id = var.hosted_zone_id
}

data "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone_name
}

resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "codebuild-bucket-${var.env}-${var.region}"
}
resource "aws_s3_bucket" "dreambooth_storage_bucket" {
  bucket = "dreambooth-worker-v1-${var.env}-${var.region}"
}
module "dreambooth_service" {
  service_name = "dreambooth"
  source = "../aws-batch-pytorch-gpu-service"
  region = "us-east-1"
  env = var.env
  vpc_id = var.vpc_id
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

  codepipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket
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


