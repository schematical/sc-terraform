data "aws_caller_identity" "current" {}
module "vpc" {
  source = "../../modules/vpc"
  vpc_name = "dev-a"
  bastion_keypair_name = "schematical-course-test"
  # bastion_ingress_ip_ranges = []
}
module "vpc_b" {
  source = "../../modules/vpc"
  vpc_name = "dev-b"
  vpc_cidr = "10.1.0.0/16"
  private_subnets = [
    {
      az = "a"
      cidr = "10.1.1.0/24",
      name = "private-a"
    },
    {
      az = "b"
      cidr = "10.1.2.0/24",
      name = "private-b"
    }
  ]
  public_subnets = [
    {
      az = "a"
      cidr = "10.1.101.0/24"
      name = "public-a"
    },
    {
      az = "b"
      cidr = "10.1.102.0/24"
      name = "public-b"
    }
  ]
}
resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = module.vpc_b.vpc_id
  vpc_id        = module.vpc.vpc_id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}
resource "aws_route" "vpc_peering_route" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
}
resource "aws_route" "vpc_peering_route_public" {
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
}
resource "aws_route" "vpc_peering_route_b" {
  route_table_id         = module.vpc_b.private_route_table_id
  destination_cidr_block = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
}
resource "local_file" "private_key" {
  content  = module.vpc.bastion_private_key_pem
  filename = "bastion-creds.pem"
  file_permission = "600"
}
resource "aws_elasticache_cluster" "elasticache_cluster" {
  cluster_id           = "course-test"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids = [aws_security_group.redis_security_group.id]
}
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "course-test"
  subnet_ids = [for o in module.vpc_b.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
}
resource "aws_security_group" "redis_security_group" {
  name        =  "course-test-redis-prod"
  description = "course-test-redis-prod-redis-prod"
  vpc_id      = module.vpc_b.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]# ["10.0.0.0/16"]
    /*security_groups = [
      module.vpc.bastion_security_group
    ]*/
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}



resource "aws_iam_user" "iam_user_joe" {
  name = "joe"
  # path = "/system/"

  tags = {
    tag-key = "test"
  }
}

resource "aws_iam_access_key" "iam_user_access_key_joe" {
  user = aws_iam_user.iam_user_joe.name
}
resource "local_file" "access_key" {
  content  = "${aws_iam_access_key.iam_user_access_key_joe.id}\n${aws_iam_access_key.iam_user_access_key_joe.secret}"
  filename = "creds.txt"
}
data "aws_iam_policy_document" "iam_policy_document_joe" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = [
      module.vpc.bastion_arn,
      "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:document/SSM-SessionManagerRunShell"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceProperties",
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
    resources = [
      "arn:aws:ssm:*:*:session/${aws_iam_user.iam_user_joe.id}-*",
      "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:document/SSM-SessionManagerRunShell"
    ]
  }
}
resource "aws_iam_user_policy" "iam_policy_document_joe" {
  name   = "joe_user_policy"
  user   = aws_iam_user.iam_user_joe.name
  policy = data.aws_iam_policy_document.iam_policy_document_joe.json
}