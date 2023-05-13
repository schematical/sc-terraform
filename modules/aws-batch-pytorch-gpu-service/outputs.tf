
output "batch_job_definition" {
  value = aws_batch_job_definition.job_definition
}
output "batch_job_queue" {
  value = aws_batch_job_queue.batch_job_queue
}