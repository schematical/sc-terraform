
resource "aws_lb_listener" "alb_listener_http" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  load_balancer_arn = var.alb_arn
  port              = 80
  protocol          = "HTTP"
}

resource "aws_lb_listener" "alb_listener_https" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = var.acm_cert_arn
}

resource "aws_lb_target_group" "alb_target_group" {
  health_check  {
    path = var.alb_target_group_health_check_path
  }
  name                = "${var.service_name}-v1-${var.env}-tg"
  port                = 80
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = var.vpc_id
}
/*resource "aws_route53_record" "route53_record" {
  name    = "${var.service_name}-${var.env}-${var.region}.${var.hosted_zone_name}"
  type    = "A"
  zone_id = var.hosted_zone_name

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}*/

resource "aws_route53_health_check" "route53_health_check" {
  port                         = 443
  type                         = "HTTPS"
  resource_path                = var.alb_target_group_health_check_path
  fqdn                         = "${var.subdomain}.${var.hosted_zone_name}"
  request_interval             = 30
  failure_threshold            = 3
  measure_latency              = true
  enable_sni                   = true
}

resource "aws_route53_record" "route53_record" {
  name    = "${var.subdomain}.${var.hosted_zone_name}"
  type    = "A"
  zone_id = var.hosted_zone_name

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.route53_health_check.id
}