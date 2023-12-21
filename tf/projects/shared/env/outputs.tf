output "ecs_cluster" {
  value = aws_ecs_cluster.ecs_cluster
}
/*
output "shared_alb" {
  value = module.shared_alb
}
output "shared_alb_http_listener_arn" {
  value = module.shared_alb.lb_http_listener_arn
}
output "shared_alb_https_listener_arn" {
  value = module.shared_alb.lb_https_listener_arn
}*/
