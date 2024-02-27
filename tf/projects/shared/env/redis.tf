resource "aws_elasticache_replication_group" "example" {
  replication_group_id       = "tf-redis-cluster"
  description                = "example description"
  node_type                  = "cache.t4g.micro"
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.default.name
  automatic_failover_enabled = true

  num_node_groups         = 4
  replicas_per_node_group = 1
  subnet_group_name = aws_elasticache_subnet_group.example.name
}
/*resource "aws_elasticache_cluster" "replica" {
  count = 0

  cluster_id           = "tf-rep-group-1-${count.index}"
  replication_group_id = aws_elasticache_replication_group.example.id

}*/
resource "aws_elasticache_parameter_group" "default" {
  name   = "cache-params"
  family      = "redis7"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }
}
resource "aws_elasticache_subnet_group" "example" {
  name       = "tf-test-cache-subnet"
  subnet_ids = [for o in var.private_subnet_mappings : o.id]
}
