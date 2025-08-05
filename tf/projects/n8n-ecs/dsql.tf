resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "aws_security_group" "postgresql_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.env_info.prod.vpc_id

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "n8n"
  engine                  = "aurora-postgresql"
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name           = "mydb"
  master_username         = "batman"
  master_password         = random_password.password.result
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  serverlessv2_scaling_configuration {
    max_capacity             = 1.0
    min_capacity             = 0.0
    seconds_until_auto_pause = 3600
  }
  vpc_security_group_ids = [aws_security_group.postgress_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}
resource "aws_rds_cluster_instance" "cluster_instance" {
  count              = 1
  identifier         = "aurora-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.postgresql.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.postgresql.engine
  engine_version     = aws_rds_cluster.postgresql.engine_version
}
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [for o in var.env_info.prod.private_subnet_mappings : o.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_security_group" "postgress_sg" {
  name        = "${local.service_name}-${local.env}-db"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.env_info.prod.vpc_id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgress_sg_ingress" {
  security_group_id = aws_security_group.postgress_sg.id
  referenced_security_group_id = module.prod_env_schematical_com.task_security_group_id
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}
resource "aws_vpc_security_group_egress_rule" "postgress_sg_egress" {
  security_group_id = aws_security_group.postgress_sg.id
  #from_port   = 0
  #to_port     = 0
  ip_protocol    = "-1"
  cidr_ipv4  = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "postgress_sg_egress_v6" {
  security_group_id = aws_security_group.postgress_sg.id
  #from_port   = 0
  #to_port     = 0
  ip_protocol    = "-1"
  cidr_ipv6  = "::/0"
}


