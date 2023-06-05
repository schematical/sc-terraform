module "dreambooth_batch_worker" {
  service_name = "dreambooth"
  source = "https://github.com/schematical/sc-terraform/blob/main/modules/aws-batch-pytorch-gpu-service#master"
  region = "us-east-1"
  env = var.env
  vpc_id = var.vpc_i
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  private_subnet_mappings = var.private_subnet_mappings

  codepipeline_artifact_store_bucket = var.codepipeline_artifact_store_bucket
  output_bucket                      = aws_s3_bucket.dreambooth_storage_bucket
  bastion_security_group = var.bastion_security_group

  codepipeline_github_owner = "yourgithub"
  codepipeline_github_project_name = "chaos-ville"
  codepipeline_github_source_branch = var.env
  codepipeline_source_buildspec_path = "batch/buildspec.yml"

}
