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
variable "subdomain" {
  type = string
}

variable "cors_allowed_hosts" {
  type = list(string)
}
/*
variable "output_bucket" {
}
*/

variable "codepipeline_artifact_store_bucket" {
}


variable "hosted_zone_name" {
}
variable "hosted_zone_id" {

}

variable "acm_cert_arn" {

}