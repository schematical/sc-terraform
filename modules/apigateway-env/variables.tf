variable "region" {
  default = "us-east-1"
}

variable "env" {}


variable "api_gateway_id" {}

variable "hosted_zone_name" {

}
variable "hosted_zone_id" {

}

variable "acm_cert_arn" {
}

/*
variable "ecs_task_execution_iam_role" {}
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "bastion_security_group" {}
*/
