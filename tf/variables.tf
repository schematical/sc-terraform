variable "envs" {
  description = "Environments"
  type        = list(string)
  default     = ["dev", "stage", "prod"]
}
variable "dev_secrets" {
  type = map(string)
}
variable "prod_secrets" {
  type = map(string)
}
