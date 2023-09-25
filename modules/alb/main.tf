resource "aws_lb" "application_load_balancer" {
  name               = "${var.service_name}-v1-${var.env}-alb"
  subnets            = var.public_subnet_mappings
  security_groups    = [aws_security_group.alb_security_group.id]

}



resource "aws_security_group" "alb_security_group" {
  name        = "${var.service_name}-${var.region}-v1-${var.env}-alb"
  description = "${var.service_name}-${var.region}-v1-${var.env}-alb"

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



