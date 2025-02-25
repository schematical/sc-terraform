locals {
  preferred_cache_cluster_azs = ["${var.region}a", "${var.region}b"]
}
resource "aws_elasticache_cluster" "elasticache_cluster" {
  cluster_id           = "${local.service_name}"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids = [aws_security_group.redis_security_group.id]
  // replication_group_id = aws_elasticache_replication_group.elasticache_cluster.id
}
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "${local.service_name}"
  subnet_ids = [for o in var.env_info.prod.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
}
resource "aws_security_group" "redis_security_group" {
  name        =  "${local.service_name}-redis-prod-${var.region}"
  description = "${local.service_name}-redis-prod-${var.region}"
  vpc_id      = var.env_info.prod.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 6379
    to_port          = 6380
    protocol         = "tcp"
    security_groups = [
      module.dev_env_schematical_com.task_security_group_id,
      module.prod_env_schematical_com.task_security_group_id
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

/*


resource "aws_elasticache_replication_group" "elasticache_cluster" {
  automatic_failover_enabled  = true
  preferred_cache_cluster_azs = local.preferred_cache_cluster_azs
  replication_group_id        = "${local.service_name}-group-1"
  description                 = "${local.service_name}-group-1"
  node_type                   = "cache.t4g.micro"
  num_cache_clusters          = 2
  parameter_group_name        = "default.redis7"
  port                        = 6379

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}




resource "aws_appautoscaling_target" "elasticache_read_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "replication-group/${aws_elasticache_cluster.elasticache_cluster.cluster_id}"
  scalable_dimension = "elasticache:replication-group:NodeGroups"
  service_namespace  = "elasticache"
}

resource "aws_appautoscaling_policy" "elasticache_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_elasticache_cluster.elasticache_cluster.cluster_id}}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.elasticache_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.elasticache_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.elasticache_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "CPUUtilization"
    }

    target_value = 2
  }
}*/
