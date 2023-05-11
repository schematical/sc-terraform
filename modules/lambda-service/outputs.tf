output "lambda_function" {
  value = aws_lambda_function.service_lambda_web
}
output "iam_role" {
  value = aws_iam_role.service_lambda_iam_role
}