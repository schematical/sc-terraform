module "vpc" {
  source = "../../modules/vpc"
  vpc_name = "dev"
  bastion_keypair_name = "schematical-course-test"
  # bastion_ingress_ip_ranges = []
}