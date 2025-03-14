# com.amazonaws.region.ssm
module "vpc" {
  source = "../../modules/vpc"
  vpc_name = var.env
  # bastion_keypair_name = "schematical_node_1"
}
/*resource "aws_security_group" "ssm_vpc_endpoint_security_group" {

}*/
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  /*security_group_ids = [
    aws_security_group.ssm_vpc_endpoint_security_group.id,
  ]*/

  private_dns_enabled = true
}