resource "aws_lb" "application_load_balancer" {
  name               = "${var.service_name}-v1-${var.env}-alb"
  subnets            =  [for o in var.public_subnet_mappings : o.id]
  security_groups    = [aws_security_group.alb_security_group.id]
  idle_timeout = var.alb_idle_timeout
  load_balancer_type = var.load_balancer_type
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


resource "aws_lb_listener" "alb_listener_http" {
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"
}

resource "aws_lb_listener" "alb_listener_https" {
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = var.acm_cert_arn
}

