output "alb_sg_id" {
  value = aws_security_group.alb_security_group.id
}
output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}