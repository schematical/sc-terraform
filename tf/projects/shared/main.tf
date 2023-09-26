module "prod_shared_env" {
  source = "./env"
  env = "prod"
  vpc_id = var.vpc_id
  public_subnet_mappings = var.public_subnet_mappings
  private_subnet_mappings = var.private_subnet_mappings
}