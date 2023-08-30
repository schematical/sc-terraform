output "lambda_function" {
  value = aws_lambda_function.service_lambda_web
}
output "iam_role" {
  value = aws_iam_role.service_lambda_iam_role
}
output "lambda_sg_id" {
  value = aws_security_group.service_lambda_sg.id
}