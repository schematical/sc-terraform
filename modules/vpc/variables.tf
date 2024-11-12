# Input variable definitions

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "example-vpc"
}
variable "region" {
  description = "The AWS Region the VPC will be booted up in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC. This is more important when peering multiple VPCs"
  type        = string
  default     = "10.0.0.0/16"
}
variable "bastion_keypair_name" {
  description = "The keypair you created for the bastion. If this is left empty no bastion should be booted up"
  type        = string
  default = ""
}
variable "bastion_ingress_rule" {
  description = "IP Address For Bastion"
  type        = string
  default     = "0.0.0.0/0"
}
variable "private_subnets" {
  description = "This is a list of the private availability zones(az), cidr blocks (cidr), and subnet names for each subnet you want. I recommend at least 1 public and 1 private for each availability zone you wish to support."
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
  description = "This is a list of the private availability zones(az), cidr blocks (cidr), and subnet names for each subnet you want. I recommend at least 1 public and 1 private for each availability zone you wish to support."
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
variable "bastion_ingress_ip_ranges" {
  description = "This is a list of the ip address ranges you want to be able to access the bastion"
  type = list(object({
    ipv6_cidr_blocks           = optional(list(string))
    cidr_blocks           = optional(list(string))
    description                = string
    from_port                  = number
    protocol                   = string
    to_port                    = number
  }))
  default = [
    {
      cidr_blocks                = ["0.0.0.0/0"]
      description                = "AllIPv4"
      from_port                  = 22
      protocol                   = "tcp"
      to_port                    = 22
    },
    {
      ipv6_cidr_blocks           = ["::/0"]
      description                = "AllIPv6"
      from_port                  = 22
      protocol                   = "tcp"
      to_port                    = 22
    }
  ]
}


variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
