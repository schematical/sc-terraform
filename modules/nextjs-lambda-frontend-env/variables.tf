variable "service_name" {
  type = string
}
variable "region" {
  default = "us-east-1"
}

variable "env" {}


variable "api_gateway_id" {}
variable "api_gateway_base_path_mapping" {}
variable "hosted_zone_name" {
}
variable "hosted_zone_id" {

}


variable "acm_cert_arn" {
}

variable "ecs_task_execution_iam_role" {}
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
# variable "bastion_security_group" {}

variable "codepipeline_artifact_store_bucket" {

}
variable "subdomain" {
  type = string
}
variable "github_owner" {
  type = string
}
variable "github_project_name" {
  type = string
}
variable "secrets" {
  type = map(string)
}
variable "source_buildspec_path" {
  type = string
  default = "buildspec.yml"
}
variable "cache_cluster_enabled" {
  default = null
  type = bool
}
variable "cache_cluster_size" {
  default = null
  type = number
}
variable "extra_env_vars" {
  type = map(string)
  default = {}
}
variable "cloudfront_subdomain" {
  type = string
  default = null
}
variable "xray_tracing_enabled" {
  type = bool
  default = false
}