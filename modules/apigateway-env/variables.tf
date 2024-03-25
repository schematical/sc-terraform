variable "region" {
  default = "us-east-1"
}
variable "domain_name" {
  default = ""
}
variable "env" {}


variable "api_gateway_id" {}

variable "hosted_zone_name" {

}
variable "hosted_zone_id" {

}

variable "acm_cert_arn" {
}
variable "xray_tracing_enabled" {
  default = false
  type=bool
}
variable "cache_cluster_enabled" {
  default = null
  type=bool
}
variable "cache_cluster_size" {
  default = null
  type=number
}
/*
variable "ecs_task_execution_iam_role" {}
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "bastion_security_group" {}
*/

