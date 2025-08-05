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
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}

variable "codepipeline_artifact_store_bucket" {

}
variable "subdomain" {
  type = string
}


variable "secrets" {
  type = map(string)
}

variable "waf_web_acl_arn" {
  type = string
}
variable "alb_arn" {
  type = string
}
variable "alb_dns_name" {
  type = string
}
variable "alb_hosted_zone_id" {
  type = string
}
variable "lb_http_listener_arn" {
  type = string
}
variable "lb_https_listener_arn" {
  type = string
}
variable "ecs_cluster_id" {
  type = string
}
variable "ecs_cluster_name" {
  type = string
}
variable "shared_alb_sg_id" {
  type = string
}
variable "codestar_connection_arn" {
  type = string
}
variable "dsql_cluster_endpoint" {
  type = string
}
variable "dsql_cluster_arn" {
  type = string
}
variable "dsql_cluster_password" {
  type = string
}