variable "envs" {
  description = "Environments"
  type        = list(string)
  default     = ["dev", "stage", "prod"]
}
/*variable "api_gateway_id" {
  description = "The APIGateway Instance Id"
  type        = string
  default     = "sc"
}
variable "api_gateway_parent_id" {
  description = "The APIGateway's Root Resource Id"
  type        = string
  default     = "sc"
}*/
variable "api_gateway_stages" {
  type = map(string)
  default = {
    dev = "x"
    stage = "y"
    prod = "z"
  }
}
