variable "service_name" {
  type        = string
  default     = "batch-gpu-compute-env-v1"
  description = "Template"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Template"
}

variable "env" {
  type        = string
  description = "Template"
}

variable "github_owner" {
  type        = string
  default     = "schematical"
  description = "Template"
}

variable "github_project_name" {
  type        = string
  default     = "schematical-com"
  description = "Template"
}

variable "github_source_branch" {
  type        = string
  default     = "main"
  description = "Template"
}

variable "code_build_image_uri" {
  type        = string
  default     = "aws/codebuild/standard:7.0"
  description = "Template"
}

variable "code_build_timeout" {
  type        = number
  default     = 5
  description = "Template"
}

variable "code_pipeline_artifact_store_bucket" {
  type        = string
  description = "Template"
}

variable "codestar_connection_arn" {
  type        = string
  default     = "arn:aws:codestar-connections:us-east-1:368590945923:connection/67d17ca5-a542-49db-9256-157204b67b1d"
  description = "Template"
}

variable "deploy_to_cluster" {
  type        = string
  default     = ""
  description = "Template"
}

variable "base_image_uri" {
  type        = string
  default     = ""
  description = "Template"
}
variable "source_buildspec_path" {
  type        = string
  default     = ""
  description = "buildspec.yml"
}

variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "env_vars" {
  type = map(string)
  default = {}
}
variable "ecs_deploy_cluster" {
  type = string
  default = ""
}
variable "ecs_deploy_service_name" {
  type = string
  default = ""
}