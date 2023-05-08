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
  default = "arn:aws:acm:us-east-1:368590945923:certificate/2df7c33d-9569-41ab-94ed-0d2638369c21"
}

variable "ecs_task_execution_iam_role" {}
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "bastion_security_group" {}

