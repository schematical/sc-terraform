
output "batch_job_definition" {
  value = aws_batch_job_definition.job_definition
}
output "batch_job_queue" {
  value = aws_batch_job_queue.batch_job_queue
}
output "batch_job_definition_iam_role" {
  value = aws_iam_role.job_definition_iam_role
}