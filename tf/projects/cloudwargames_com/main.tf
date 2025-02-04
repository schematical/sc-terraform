#terraform import module.project_cloudwargames_com.aws_route53_zone.cloudwargames_com Z00408211L2QQHQLJ5SKA
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}
locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:cloudwargames-com-$${stageVariables.ENV}-www/invocations"
  service_name = "cloudwargames-com"
  domain_name = "cloudwargames.com"
}

resource "aws_route53_zone" "cloudwargames_com" {
  name = local.domain_name
}
resource "aws_route53_record" "route53_record_a1" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = local.domain_name
  type    = "A"
  ttl     = 300
  records = [
    "3.13.222.255",
    "3.13.246.91",
    "3.130.60.26"
  ]
}

resource "aws_route53_record" "route53_record_links_cname" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = "links.${local.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [
    "cname.plutolinks.com"
  ]
}








resource "aws_acm_certificate" "cloudwargames_com_cert" {
  domain_name       = aws_route53_zone.cloudwargames_com.name
  subject_alternative_names = ["*.${aws_route53_zone.cloudwargames_com.name}"]
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws_acm_certificate_route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.cloudwargames_com_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.cloudwargames_com.zone_id
}
/*resource "aws_route53_record" "cloudwargames-com-a" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    =  local.domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}*/
resource "aws_route53_record" "cloudwargames-com-ck1" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = "ckespa.cloudwargames.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "spf.dm-rm8vgvoy.sg7.convertkit.com."
  ]
}
resource "aws_route53_record" "cloudwargames-com-ck2" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = "cka._domainkey.cloudwargames.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "dkim.dm-rm8vgvoy.sg7.convertkit.com."
  ]
}
resource "aws_route53_record" "cloudwargames-com-ck3" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = "_dmarc.cloudwargames.com"
  type    = "TXT"
  ttl     = 300
  records = [
    "v=DMARC1; p=none;"
  ]
}



resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = aws_acm_certificate.cloudwargames_com_cert.arn
  domain_name     = local.domain_name
  endpoint_configuration {
    types = ["EDGE"]
  }
}
/*resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  base_path   = ""
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.id
  api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
}*/
resource "aws_route53_record" "cloudwargames-com-mx" {
  zone_id = aws_route53_zone.cloudwargames_com.zone_id
  name    = local.domain_name
  type    = "MX"
  ttl     = "30"
  records = [
    "10 ASPMX.L.GOOGLE.COM.",
    "20 ALT1.ASPMX.L.GOOGLE.COM.",
    "30 ALT2.ASPMX.L.GOOGLE.COM.",
    "40 ASPMX2.GOOGLEMAIL.COM.",
    "50 ASPMX3.GOOGLEMAIL.COM."
  ]
}


resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = local.service_name
      version = "1.0"
    }
    paths = {

    }
  })

  name = "${local.service_name}-v1"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_gateway_root_resource_method_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method          = aws_api_gateway_method.api_gateway_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_BINARY"
  uri = local.www_lambda_arn

}

resource "aws_api_gateway_resource" "api_gateway_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "api_gateway_proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "api_gateway_proxy_resource_method_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.api_gateway_proxy_resource.id
  http_method          = aws_api_gateway_method.api_gateway_proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_BINARY"
  uri = local.www_lambda_arn

  request_parameters = {
    "integration.request.path.proxy": "method.request.path.proxy"
  }
  cache_key_parameters = ["method.request.path.proxy"]
}

resource "aws_dynamodb_table" "dynamodb_table_post" {
  name           = "cloudwargamesComPost"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PostId"
  // range_key      = "PublicDate"

  attribute {
    name = "PostId"
    type = "S"
  }

  /*  attribute {
      name = "Title"
      type = "S"
    }

    attribute {
      name = "Body"
      type = "S"
    }*/
  /*  attribute {
      name = "PublicDate"
      type = "S"
    }*/
  /*
    ttl {
      attribute_name = "TimeToExist"
      enabled        = false
    }*/

  /* global_secondary_index {
     name               = "GameTitleIndex"
     hash_key           = "GameTitle"
     range_key          = "TopScore"
     write_capacity     = 10
     read_capacity      = 10
     projection_type    = "INCLUDE"
     non_key_attributes = ["UserId"]
   }*/

  tags = {
    Name        = "cloudwargames-com"
  }
}


/*resource "aws_elasticache_serverless_cache" "elasticache_serverless_cache" {
  engine = "redis"
  name   = "${local.service_name}-${var.region}"
  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 1000
    }
  }
  #daily_snapshot_time      = "09:00"
  description              = "${local.service_name}-${var.region}"
  # kms_key_id               = aws_kms_key.test.arn
  major_engine_version     = "7"
  snapshot_retention_limit = 1
  security_group_ids       = [aws_security_group.redis_security_group.id]
  subnet_ids               = [for o in var.env_info.prod.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
}*/
/*resource "aws_elasticache_cluster" "elasticache_cluster" {
  cluster_id           = "${local.service_name}"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids = [aws_security_group.redis_security_group.id]
}
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "${local.service_name}"
  subnet_ids = [for o in var.env_info.prod.private_subnet_mappings : o.id] # values(var.private_subnet_mappings)
}*/
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
      module.dev_env_cloudwargames_com.task_security_group_id,
      // module.prod_env_cloudwargames_com.task_security_group_id
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


module "nextjs_lambda_frontend_base" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../modules/nextjs-lambda-frontent-base"


  base_domain_name = local.domain_name
  service_name     = local.service_name
  api_gateway_stage_name = "dev"
  aws_route53_zone_id = aws_route53_zone.cloudwargames_com.zone_id
}

module "dev_env_cloudwargames_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.cloudwargames_com.id
  hosted_zone_name = aws_route53_zone.cloudwargames_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.cloudwargames_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  secrets = var.env_info.dev.secrets
  dynamodb_table_arns = [
    aws_dynamodb_table.dynamodb_table_post.arn,

  ]
  service_name = local.service_name
  subdomain = "dev"
  redis_host =  "" # join(",", [for o in aws_elasticache_cluster.elasticache_cluster.cache_nodes : o.address])
  waf_web_acl_arn = var.env_info.prod.waf_web_acl_arn
  alb_arn = var.env_info.dev.shared_alb.alb_arn
  alb_dns_name = var.env_info.dev.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.dev.shared_alb.alb_hosted_zone_id
  ecs_cluster_id = var.env_info.dev.ecs_cluster.id
  ecs_cluster_name = "prod-v1"
  lb_http_listener_arn = var.env_info.dev.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.dev.shared_alb_https_listener_arn
  shared_alb_sg_id = var.env_info.dev.shared_alb.alb_sg_id
}
/*

module "prod_env_cloudwargames_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.cloudwargames_com.id
  hosted_zone_name = aws_route53_zone.cloudwargames_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.cloudwargames_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  service_name = local.service_name
  subdomain = "www"
  secrets = var.env_info.prod.secrets

  dynamodb_table_arns = [
    aws_dynamodb_table.dynamodb_table_post.arn,

  ]
  redis_host =  join(",", [for o in aws_elasticache_cluster.elasticache_cluster.cache_nodes : o.address]) # join(",", [for o in aws_elasticache_serverless_cache.elasticache_serverless_cache.endpoint : o.address])
  waf_web_acl_arn = var.env_info.prod.waf_web_acl_arn

  alb_arn = var.env_info.prod.shared_alb.alb_arn
  alb_dns_name = var.env_info.prod.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.prod.shared_alb.alb_hosted_zone_id
  ecs_cluster_id = var.env_info.prod.ecs_cluster.id
  ecs_cluster_name = "prod-v1"
  lb_http_listener_arn = var.env_info.prod.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.prod.shared_alb_https_listener_arn
  shared_alb_sg_id = var.env_info.prod.shared_alb.alb_sg_id
}*/
