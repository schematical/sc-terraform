module "prod_shared_env" {
  source = "../../modules/shared_env"
  env = "prod"
  vpc_id = var.vpc_id
  public_subnet_mappings = var.public_subnet_mappings
  private_subnet_mappings = var.private_subnet_mappings
  shared_acm_cert_arn = aws_acm_certificate.shared_acm_cert.arn
}