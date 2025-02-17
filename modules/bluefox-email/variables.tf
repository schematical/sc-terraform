/*
variable "email_address" {
  type = string
}*/

variable "domains" {
  type = list(string)
}
variable "region" {
  type = string
  default = "us-east-1"
}
variable "iam_username" {
  type = string
  default = "bluefoxemail"
}