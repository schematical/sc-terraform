
variable "project_name" {
  default = "shiporgetoffthepot-com-v1"
}
variable "region" {
  default = "us-east-1"
}

variable "env" {}


variable "hosted_zone_name" {
}
variable "hosted_zone_id" {

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
  default = ""
}
variable "secrets" {
  type = map(string)
}



variable env_info {
  type = object({
    name                               = string
    vpc_id                             = string
    private_subnet_mappings            = map(any)
    codepipeline_artifact_store_bucket = object({
      arn: string
      bucket: string
    })
    api_gateway_stage_id = string
    bastion_security_group = string
    secrets  = map(string)
    shared_alb = optional(object({
      alb_sg_id: string
      alb_arn: string
      alb_hosted_zone_id: string
      alb_dns_name: string
    }))
    shared_alb_http_listener_arn = optional(string)
    shared_alb_https_listener_arn = optional(string)
    ecs_cluster = optional(object({
      arn: string
      id: string
    }))
    rds_instance = optional(object({
      address: string
    }))
  })
}

