resource "aws_dsql_cluster" "dsql_cluster" {
  deletion_protection_enabled = true

  tags = {
    Name = local.service_name
    Env     = "prod"
    Region  = var.region
  }
}