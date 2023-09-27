output "prod_shared_env" {
  value = module.prod_shared_env
}
output "shared_acm_cert" {
  value = aws_acm_certificate.shared_acm_cert
}