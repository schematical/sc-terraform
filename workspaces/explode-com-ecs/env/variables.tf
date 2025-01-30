variable "service_name" {
  type = string
}
variable "region" {
  default = "us-east-1"
  type = string
}
variable "env" {}

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



variable "codepipeline_artifact_store_bucket" {

}
variable "subdomain" {
  type = string
}






