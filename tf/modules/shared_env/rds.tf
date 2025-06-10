
resource "aws_security_group" "prod_rds_sg" {
  name        = "shared-us-east1-v1-prod-alb"
  description = "shared-us-east1-v1-prod-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = var.vpc_id
}
resource "aws_db_subnet_group" "prod_rds_subnet_group" {
  name       = "prod_rds_subnet_group"
  subnet_ids = [for o in var.private_subnet_mappings : o.id]

  tags = {
    Env = "prod"
  }
}


resource "aws_db_instance" "prod_rds" {
  count=0
  identifier = "shared-v1-prod"
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.prod_rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.prod_rds_subnet_group.name
}