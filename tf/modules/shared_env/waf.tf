resource "aws_wafv2_regex_pattern_set" "example" {
  name                  = "example"
  regular_expression {
    regex_string = "/blockme"
  }

  regular_expression {
    regex_string = "/\\.htaccess"
  }
  scope       = "REGIONAL"
}

resource "aws_wafv2_web_acl" "schematical_shared_waf_acl" {
  name        = "schematical-shared-waf-acl"
  description = "schematical-shared-waf-acl"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }
  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"

        /*scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }*/
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "schematical-shared-waf-acl"
      sampled_requests_enabled   = false
    }

  }



  rule {
    name     = "regex"
    priority = 2

    action {
      captcha {}
    }

    statement {
      /*regex_match_statement {
        regex_string = "/\\.htaccess"
        # regex_string = "\\/wp-admin\\/.*|\\/config|\\/\\.htaccess"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 2
          type     = "NONE"
        }
      }*/
      regex_pattern_set_reference_statement{


        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 2
          type     = "NONE"
        }
        arn = aws_wafv2_regex_pattern_set.example.arn
      }
    }




    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "schematical-shared-waf-acl"
      sampled_requests_enabled   = true
    }
  }
  /*rule {
    name     = "ChallengeAllRequests"
    priority = 3

    action {
      challenge {} # Challenges every request
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.challenge_all.arn
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 1
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ChallengeAllRequests"
      sampled_requests_enabled   = true
    }
  }*/

  /*rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 3
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }
        }
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "CategorySearchEngine"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }*/










  tags = {
    # Tag1 = "Value1"
    # Tag2 = "Value2"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "schematical-shared-waf-acl-default"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_regex_pattern_set" "challenge_all" {
  name        = "challenge-all"
  description = "Regex pattern set to match all requests"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "^.*$" # Matches everything
  }
}
/*resource "aws_wafv2_web_acl" "challenge_wafv2_web_acl" {
  name        = "challenge"
  scope       = "REGIONAL"
  description = "WebACL that challenges every request"

  default_action {
    allow {}
  }

  rule {
    name     = "ChallengeAllRequests"
    priority = 1

    action {
      challenge {} # Challenges every request
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.challenge_all.arn
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 1
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ChallengeAllRequests"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "challenge-web-acl"
    sampled_requests_enabled   = true
  }
}*/
resource "aws_wafv2_web_acl_logging_configuration" "challenge_wafv2_web_acl_logging_configuration" {

  log_destination_configs = [aws_cloudwatch_log_group.example.arn]
  resource_arn            = aws_wafv2_web_acl.schematical_shared_waf_acl.arn
}
resource "aws_cloudwatch_log_group" "example" {
  name = "aws-waf-logs-schematical-shared"
}

resource "aws_wafv2_web_acl_logging_configuration" "example" {

  log_destination_configs = [aws_cloudwatch_log_group.example.arn]
  resource_arn            = aws_wafv2_web_acl.schematical_shared_waf_acl.arn

}
resource "aws_cloudwatch_log_resource_policy" "example" {
  policy_document = data.aws_iam_policy_document.example.json
  policy_name     = "schematical-shared-waf-acl"
}

data "aws_iam_policy_document" "example" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.example.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}