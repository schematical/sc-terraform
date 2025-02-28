variable "service_name" {
  type = string
}
variable "region" {
  default = "us-east-1"
  type = string
}
variable "env" {}
variable "api_gateway_id" {}
variable "api_gateway_base_path_mapping" {
  type = string
}
variable "hosted_zone_name" {
  type = string
}
variable "hosted_zone_id" {
  type = string
}
variable "acm_cert_arn" {
  type = string
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
variable "secrets" {
  type = map(string)
}
variable "codestar_connection_arn" {
  type = string
}