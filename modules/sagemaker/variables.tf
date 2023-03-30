variable "region" {
  default = "us-east-1"
}
variable "service_name" {
  default = "sagemaker-test"
}
variable "env" {}
variable "vpc_id" {
}


variable "code_pipeline_artifact_store_bucket" {}

variable "ecs_task_execution_iam_role" {}
variable "private_subnet_mappings" {
  type = map(any)
}

