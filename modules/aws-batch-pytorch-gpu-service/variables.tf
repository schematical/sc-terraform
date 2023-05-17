variable "service_name" {
  type    = string
  default = "pytorch-gpu-service-v1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "Dev"
}

variable "vpc_id" {
  type = string
}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "output_bucket" {
}
variable "codepipeline_artifact_store_bucket" {
  type = object({
    # id: string,
    arn: string
    bucket: string
  })
}
variable "instance_types" {
  type    = list(string)
  default = ["g4dn.2xlarge"]
}

variable "max_vcpus" {
  type    = number
  default = 8
}

variable "min_vcpus" {
  type    = number
  default = 0
}



variable "codebuild_image_uri" {
  type    = string
  default = "aws/codebuild/standard:3.0"
}

variable "codebuild_timeout" {
  type    = number
  default = 5
}



variable "source_code_bucket_object_key" {
  type    = string
  default = "cf-pytorch-gpu-service-src.zip"
}

variable "ecs_task_execution_iam_role" {}
variable "bastion_security_group" {}

variable "codepipeline_github_owner" {
  type = string
  default = "schematical"
}
variable "codepipeline_github_project_name" {
  type = string
  default = "sc-terraform"
}
variable "codepipeline_github_source_branch" {
  type = string
  default = "main"
}
variable "codepipeline_source_buildspec_path" {
  type = string
  default = "modules/aws-batch-pytorch-gpu-service/build/buildspec.yml"
}
