resource "aws_acm_certificate" "shared_acm_cert" {
  domain_name       = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}.com"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}