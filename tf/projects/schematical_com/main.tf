data "aws_caller_identity" "current" {}
locals {
  www_lambda_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:schematical-com-$${stageVariables.ENV}-www/invocations"
  service_name = "schematical-com"
  domain_name = "schematical.com"
}
provider "aws" {
  region = "us-east-1"
  # alias  = "east"
}
resource "aws_acm_certificate" "schematical_com_cert" {
  domain_name       = aws_route53_zone.schematical_com.name
  subject_alternative_names = ["*.${aws_route53_zone.schematical_com.name}"]
  validation_method = "DNS"
  tags = {
    Primary = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "schematical_com" {
  name = local.domain_name
}
resource "aws_route53_record" "schematical-com-txt" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "schematical.com"
  type    = "TXT"
  ttl     = 3600
  records = [
    "google-site-verification=83tJ_uXjBls0FhUPPs-D3ve-ZHHNXzkeTUe9CX9q7UE",
    "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCACWRiAp4JqK/LfWDGoVhYzza5ZD5O8D3KqUCIE4R8cmsntfBFE+krQTWAT4LTMoEpJOZI8iAvS64JDmTV13ugZIOFTuTmlu1HTjyZAhZ8+Ehk7pBudahPfjKR1sV+OzrEZYdyKMOMWoDoRzFm36qSoQZThx2Z7UgB1X+cVLCHdwIDAQAB",
    // "v=spf1 a mx include:spf.mtasv.net ~all",
    "v=spf1 include:_spf.google.com ~all"
  ]
}
/*resource "aws_route53_record" "schematical-com-ns" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = ""
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.schematical_com.name_servers
}*/

resource "aws_route53_record" "schematical-com-a" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    =  local.domain_name
  type    = "A"
  alias {
    name = var.env_info.prod.shared_alb.alb_dns_name
    zone_id = var.env_info.prod.shared_alb.alb_hosted_zone_id
    // name                   = aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_domain_name
    // zone_id                =  aws_api_gateway_domain_name.api_gateway_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}
resource "aws_lb_listener_rule" "aws_lb_listener_rule_http" {
  listener_arn = var.env_info.prod.shared_alb_http_listener_arn
  priority     = 3

  action {
    type = "forward"
    target_group_arn = module.prod_env_schematical_com.target_group_arn
  }

  condition {
    host_header {
      values = [local.domain_name]
    }
  }
}
resource "aws_lb_listener_rule" "aws_lb_listener_rule_https" {
  listener_arn = var.env_info.prod.shared_alb_https_listener_arn
  priority     = 3

  action {
    type = "forward"
    target_group_arn = module.prod_env_schematical_com.target_group_arn
  }

  condition {
    host_header {
      values = [local.domain_name]
    }
  }
}
resource "aws_route53_record" "schematical-com-ck1" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "ckespa.schematical.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "spf.dm-rm8vgvoy.sg7.convertkit.com."
  ]
}
resource "aws_route53_record" "schematical-com-ck2" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "cka._domainkey.schematical.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "dkim.dm-rm8vgvoy.sg7.convertkit.com."
  ]
}
resource "aws_route53_record" "schematical-com-ck3" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "_dmarc.schematical.com"
  type    = "TXT"
  ttl     = 300
  records = [
    "v=DMARC1; p=none; rua=mailto:servers@schematical.com"
  ]
}



resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  certificate_arn = aws_acm_certificate.schematical_com_cert.arn
  domain_name     = "schematical.com"
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
resource "aws_route53_record" "schematical-com-mx" {
  zone_id = aws_route53_zone.schematical_com.zone_id
  name    = "schematical.com"
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
resource "aws_ses_domain_identity" "ses_domain_identity" {
  domain = "schematical.com"
}


resource "aws_api_gateway_rest_api" "api_gateway" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {

    }
  })

  name = "schematical-com-v1"

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
  name           = "SchematicalComPost"
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
    Name        = "schematical-com"
  }
}

# Product table - stores individual products from each provider
resource "aws_dynamodb_table" "dynamodb_table_products" {
  name           = "products"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing
  hash_key       = "providerKey"      # Partition key
  range_key      = "providerId"       # Sort key

  attribute {
    name = "providerKey"
    type = "S"
  }

  attribute {
    name = "providerId"
    type = "S"
  }

  # Optional: Add TTL attribute for future use
  ttl {
    attribute_name = "ttl"
    enabled        = false  # Disabled for now, can enable later
  }

  tags = {
    Name        = "ProductCache"
    Environment = "poc"
    Project     = "multi-retailer-search"
  }
}

# ProductSearch table - stores search results with references to products
resource "aws_dynamodb_table" "dynamodb_table_product_searches" {
  name           = "product-searches"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing
  hash_key       = "searchKey"        # Partition key (URI-like search identifier)

  attribute {
    name = "searchKey"
    type = "S"
  }

  # Optional: Add TTL attribute for future use
  ttl {
    attribute_name = "ttl"
    enabled        = false  # Disabled for now, can enable later
  }

  tags = {
    Name        = "ProductSearchCache"
    Environment = "poc"
    Project     = "multi-retailer-search"
  }
}


module "nextjs_lambda_frontend_base" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "../../../modules/nextjs-lambda-frontent-base"


  base_domain_name = local.domain_name
  service_name     = local.service_name
  api_gateway_stage_name = "dev"
  aws_route53_zone_id = aws_route53_zone.schematical_com.zone_id
}

module "dev_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "dev"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.schematical_com.id
  hosted_zone_name = aws_route53_zone.schematical_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.schematical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group
  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  secrets = var.env_info.dev.secrets
  dynamodb_table_arns = [
    aws_dynamodb_table.dynamodb_table_post.arn,

  ]
  service_name = local.service_name
  subdomain = "dev"
  redis_host =  join(",", [for o in aws_elasticache_cluster.elasticache_cluster.cache_nodes : o.address]) # join(",", [for o in aws_elasticache_serverless_cache.elasticache_serverless_cache.endpoint : o.address])
  waf_web_acl_arn = var.env_info.prod.waf_web_acl_arn
  alb_arn = var.env_info.dev.shared_alb.alb_arn
  alb_dns_name = var.env_info.dev.shared_alb.alb_dns_name
  alb_hosted_zone_id = var.env_info.dev.shared_alb.alb_hosted_zone_id
  ecs_cluster_id = var.env_info.dev.ecs_cluster.id
  ecs_cluster_name = "prod-v1"
  lb_http_listener_arn = var.env_info.dev.shared_alb_http_listener_arn
  lb_https_listener_arn = var.env_info.dev.shared_alb_https_listener_arn
  shared_alb_sg_id = var.env_info.dev.shared_alb.alb_sg_id
  codestar_connection_arn = var.env_info.dev.codestar_connection_arn
  ecs_desired_task_count = 0
}

module "prod_env_schematical_com" {
  # depends_on = [aws_api_gateway_integration.api_gateway_root_resource_method_integration]
  source = "./env"
  env = "prod"
  vpc_id = var.env_info.dev.vpc_id
  hosted_zone_id = aws_route53_zone.schematical_com.id
  hosted_zone_name = aws_route53_zone.schematical_com.name
  ecs_task_execution_iam_role = var.ecs_task_execution_iam_role
  api_gateway_id = aws_api_gateway_rest_api.api_gateway.id
  private_subnet_mappings = var.env_info.dev.private_subnet_mappings
  acm_cert_arn = aws_acm_certificate.schematical_com_cert.arn
  codepipeline_artifact_store_bucket = var.env_info.dev.codepipeline_artifact_store_bucket
  # bastion_security_group = var.bastion_security_group

  api_gateway_base_path_mapping = aws_api_gateway_rest_api.api_gateway.root_resource_id
  service_name = local.service_name
  subdomain = "www"
  secrets = var.env_info.prod.secrets

  dynamodb_table_arns = [
    aws_dynamodb_table.dynamodb_table_post.arn,
    aws_dynamodb_table.dynamodb_table_products.arn,
    aws_dynamodb_table.dynamodb_table_product_searches.arn,

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
  codestar_connection_arn = var.env_info.prod.codestar_connection_arn
  ecs_desired_task_count = 1
}