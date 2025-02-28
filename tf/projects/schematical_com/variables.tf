variable "region" {
  default = "us-east-1"
}


variable "ecs_task_execution_iam_role" {}

/*
variable "vpc_id" {}
variable "private_subnet_mappings" {
  type = map(any)
}
variable "codepipeline_artifact_store_bucket" {}
*/

variable env_info {
  type = map(object({
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
    shared_acm_cert_arn = optional(string)
    shared_alb = optional(
      object({
        alb_sg_id = optional(string, ""),
        alb_arn = optional(string, ""),
        alb_hosted_zone_id = optional(string, ""),
        alb_dns_name = optional(string, ""),
      }),
      null
     /* {
        alb_sg_id : "",
        alb_arn : "",
        alb_hosted_zone_id  : "",
        alb_dns_name : "",
      }*/
    )
    shared_alb_http_listener_arn = optional(string)
    shared_alb_https_listener_arn = optional(string)
    ecs_cluster = optional(object({
      arn: string
      id: string
    }))
    rds_instance = optional(object({
      address: string
    }))
    waf_web_acl_arn: string
    codestar_connection_arn: string
  }))
}
