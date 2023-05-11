

variable "region" {
  default = "us-east-1"
}

variable "env" {}

variable "secrets" {
  type = map(string)
}
variable "api_gateway_id" {}


variable "ecs_task_execution_iam_role" {}
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "codepipeline_artifact_store_bucket" {
  type = object({
    arn: string
    bucket: string
  })
}
variable "bastion_security_group" {}
variable "api_gateway_base_path_mapping" {}
variable "api_gateway_stage_id" {}

