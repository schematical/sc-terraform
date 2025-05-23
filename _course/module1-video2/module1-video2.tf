data "aws_caller_identity" "current" {}
module "vpc" {
  source = "../../modules/vpc"
  vpc_name = "dev"
  bastion_keypair_name = "schematical-course-test"
  # bastion_ingress_ip_ranges = []
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
  subnet_ids = [for o in module.vpc.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
}
resource "aws_security_group" "redis_security_group" {
  name        =  "course-test-redis-prod"
  description = "course-test-redis-prod-redis-prod"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 81
    protocol         = "tcp"
    security_groups = [
      module.vpc.bastion_security_group
    ]
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