output "alb_sg_id" {
  value = aws_security_group.alb_security_group.id
}
variable "alb_arn" {
  value    = aws_lb.application_load_balancer.arn
}
variable "alb_hosted_zone_id" {
  value    = aws_lb.application_load_balancer.zone_id
}
variable "alb_dns_name" {
  value    = aws_lb.application_load_balancer.dns_name
}

