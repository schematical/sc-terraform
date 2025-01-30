locals {
  domain_name = "splitgpt.com"
}
resource "aws_s3_bucket" "code_pipeline_artifact_store_bucket" {
  # Add your bucket configuration here
}

resource "aws_iam_role" "ecs_task_execution_iam_role" {
  name = "ECSTaskExecutionIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}
resource "aws_iam_role" "anywhere_iam_role" {
  name = "ECSAnywhereIAMRole"
  path = "/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}


resource "aws_s3_bucket" "codepipeline_artifact_store_bucket" {
  bucket = "explode-com-codebuild-v1"
}


module "prod_env" {
  source = "./env"

  acm_cert_arn                       = aws_acm_certificate.shared_acm_cert.arn
  codepipeline_artifact_store_bucket = aws_s3_bucket.codepipeline_artifact_store_bucket
  ecs_task_execution_iam_role        = aws_iam_role.ecs_task_execution_iam_role
  env                                = "prod"
  hosted_zone_id                     = aws_route53_zone.explodeme_com.id
  hosted_zone_name                   = aws_route53_zone.explodeme_com.name
  service_name                       = "explodeme-com"
  subdomain                          = ""
}