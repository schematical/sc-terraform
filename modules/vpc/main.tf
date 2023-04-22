
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block       =  var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(
    {
      Name = var.vpc_name
    },
    {
      Region = var.region
    },
    var.vpc_tags
  )
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id = values(aws_subnet.public_subnets)[0].id
  tags = {
    Name = "${var.vpc_name}-${var.region}-nat"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Name = "${var.vpc_name}-${var.region}-igw"
  }
}
resource "aws_subnet" "private_subnets" {
  for_each = {
    for index, vm in var.private_subnets:
    vm.name => vm # Perfect, since VM names also need to be unique
    # OR: index => vm (unique but not perfect, since index will change frequently)
    # OR: uuid() => vm (do NOT do this! gets recreated everytime)
  }
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = join("", [var.region, each.value.az])
  tags = {
    Name = join(
      "-",
      [
        var.vpc_name,
        var.region,
        each.value.name
      ]
    )
    Region: var.region
  }
}
resource "aws_subnet" "public_subnets" {

  for_each = {
    for index, vm in var.public_subnets:
    vm.name => vm # Perfect, since VM names also need to be unique
    # OR: index => vm (unique but not perfect, since index will change frequently)
    # OR: uuid() => vm (do NOT do this! gets recreated everytime)
  }
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = join("", [var.region, each.value.az])
  tags = {
    Name = join(
      "-",
      [
        var.vpc_name,
        var.region,
        each.value.name
      ]
    )
    Region: var.region
  }
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  for_each = aws_subnet.public_subnets
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
  for_each = aws_subnet.private_subnets
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}
resource "aws_route" "public_route_igw" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}
resource "aws_route" "private_route_nat" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_route_table.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id

  // depends_on = aws_route_table_association.private_subnet_route_table_association
}
resource "aws_internet_gateway_attachment" "internet_gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
  vpc_id              = aws_vpc.main.id
}
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
}
resource "aws_vpc_endpoint_route_table_association" "s3_vpc_endpoint_route_table_association" {
  route_table_id  = aws_route_table.private_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_vpc_endpoint.id
}
resource "aws_instance" "bastion" {
  ami                          = "ami-0557a15b87f6559cf"
  instance_type                = "t2.nano"
  key_name                     = var.bastion_keypair_name
  subnet_id                    = values(aws_subnet.public_subnets)[0].id
  associate_public_ip_address  = true
  instance_initiated_shutdown_behavior = "terminate"
  security_groups            = [aws_security_group.bastion.id]


  tags = {
    "Name"                      = join("-", [var.vpc_name, "bastion"])
    "VPC"                       = var.vpc_name
    "Region"                    = var.region
  }
}

resource "aws_security_group" "bastion" {
  name_prefix                  = join("-", [var.vpc_name, var.region, "bastion"])
  description                  = join("-", [var.vpc_name, var.region, "bastion"])
  vpc_id                       = aws_vpc.main.id

  ingress {
    cidr_blocks                = [var.bastion_ingress_rule]
    description                = "AllIPv4"
    from_port                  = 22
    protocol                   = "tcp"
    to_port                    = 22
  }
  ingress {
    ipv6_cidr_blocks           = ["::/0"]
    description                = "AllIPv6"
    from_port                  = 22
    protocol                   = "tcp"
    to_port                    = 22
  }

  egress {
    cidr_blocks                = ["0.0.0.0/0"]
    description                = "AllIPv4"
    from_port                  = 0
    protocol                   = -1
    to_port                    = 0
  }

  egress {
    ipv6_cidr_blocks           = ["::/0"]
    description                = "AllIPv6"
    from_port                  = 0
    protocol                   = -1
    to_port                    = 0
  }
}