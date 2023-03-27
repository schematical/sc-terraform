# Input variable definitions

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "example-vpc"
}
variable "region" {
  description = "The Region the VPC will be booted up in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "private_subnets" {
  type = list(object({
    az = string
    cidr = string
    name = string
  }))
  default = [
    {
      az = "a"
      cidr = "10.0.1.0/24",
      name = "private-a"
    },
    {
      az = "b"
      cidr = "10.0.2.0/24",
      name = "private-b"
    }
  ]
}


variable "public_subnets" {
  type = list(object({
    az = string
    cidr = string
    name = string
  }))
  default = [
    {
      az = "a"
      cidr = "10.0.101.0/24"
      name = "public-a"
    },
    {
      az = "b"
      cidr = "10.0.102.0/24"
      name = "public-b"
    }
  ]
}
variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
