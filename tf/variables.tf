variable "envs" {
  description = "Environments"
  type        = list(string)
  default     = ["dev", "stage", "prod"]
}
variable "secrets" {
  type = map(string)
}
