output "alb_sg_id" {
  value = aws_security_group.alb_security_group.id
}
output "alb_arn" {
  value    = aws_lb.application_load_balancer.arn
}
output "alb_hosted_zone_id" {
  value    = aws_lb.application_load_balancer.zone_id
}
output "alb_dns_name" {
  value    = aws_lb.application_load_balancer.dns_name
}
output "lb_http_listener_arn" {
  value    = aws_lb_listener.alb_listener_http.arn
}
output "lb_https_listener_arn" {
  value    = aws_lb_listener.alb_listener_https.arn
}
output "alb_name" {
  value    = aws_lb.application_load_balancer.name
}
output "alb_id" {
  value    = aws_lb.application_load_balancer.id
}
output "alb_name_prefix" {
  value    = aws_lb.application_load_balancer.name_prefix
}
output "alb_arn_suffix" {
  value    = aws_lb.application_load_balancer.arn_suffix
}
