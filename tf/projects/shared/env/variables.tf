variable "env" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_mappings" {
  type = map(any)
}
variable "private_subnet_mappings" {
  type = map(any)
}