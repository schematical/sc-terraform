

resource "aws_lb_target_group" "alb_target_group" {
  health_check  {
    path = var.alb_target_group_health_check_path
    interval = var.health_interval
    healthy_threshold = var.health_threshold
    timeout = var.health_timeout
  }
  name                = "${var.service_name}-v1-${var.env}-tg"
  port                = var.container_port
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = var.vpc_id
}

resource "aws_lb_listener_rule" "aws_lb_listener_rule_http" {
  listener_arn = var.lb_http_listener_arn

  priority     = var.lb_listener_rule_http_rule_priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }


  condition {
    host_header {
      values = ["${var.subdomain}.${var.hosted_zone_name}"]
    }
  }
}
resource "aws_lb_listener_rule" "aws_lb_listener_rule_https" {
  listener_arn = var.lb_https_listener_arn

  priority     = var.lb_listener_rule_http_rule_priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain}.${var.hosted_zone_name}"]
    }
  }
}
resource "aws_route53_record" "route53_record" {
  name    = "${var.subdomain}.${var.hosted_zone_name}"
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }

  # health_check_id = aws_route53_health_check.route53_health_check.id
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

/*
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
*/

