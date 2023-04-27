variable "service_name" {
  type    = string
  default = "pytorch-gpu-service-v1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "dev"
}


variable "vpc_id" {
  type = string
}
variable "private_subnet_mappings" {
  type = map(any)
}
/*
variable "output_bucket" {
}
*/

variable "codepipeline_artifact_store_bucket" {
}

variable "api_gateway_id" {}

variable "hosted_zone_name" {
}
variable "hosted_zone_id" {

}

variable "acm_cert_arn" {

}