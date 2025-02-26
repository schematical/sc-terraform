module "shared_alb" {
  source = "../../../modules/alb"
  service_name = "shared"
  env = var.env
  public_subnet_mappings = module.vpc.public_subnet_mappings
  vpc_id = module.vpc.vpc_id
  acm_cert_arn = var.acm_cert_arn
}
