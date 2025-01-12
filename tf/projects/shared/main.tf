
resource "aws_acm_certificate" "shared_acm_cert" {
  domain_name       = "schematical.com"
  subject_alternative_names = ["*.schematical.com"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

module "prod_shared_env" {
  source = "./env"
  env = "prod"
  vpc_id = var.vpc_id
  public_subnet_mappings = var.public_subnet_mappings
  private_subnet_mappings = var.private_subnet_mappings
  shared_acm_cert_arn = aws_acm_certificate.shared_acm_cert.arn
}