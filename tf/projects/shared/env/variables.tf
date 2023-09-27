variable "env" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "shared_acm_cert_arn" {
  type = string
}
variable "public_subnet_mappings" {
  type = map(any)
}
variable "private_subnet_mappings" {
  type = map(any)
}