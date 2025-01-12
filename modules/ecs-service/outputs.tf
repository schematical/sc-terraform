output "ecs_task_execution_iam_role_arn" {
  value    = aws_iam_role.task_iam_role.arn
}
output "ecs_task_execution_iam_role_name" {
  value    = aws_iam_role.task_iam_role.name
}
output "ecs_task_definition_arn" {
  value    = aws_ecs_task_definition.ecs_task_definition.arn
}
output "ecs_service_name" {
  value    = aws_ecs_service.ecs_service.name
}
output "task_security_group_id" {
  value    = aws_security_group.task_security_group.id
}

