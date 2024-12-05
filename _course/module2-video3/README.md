#
NOTE: This does not have a standalone module. 
For the Terraform portion of this I used actual Terraform modules from my live setup.

## Specific Files Include:
The Web ACL [tf/projects/shared/env/waf.tf](../../tf/projects/shared/env/waf.tf)
The Association [tf/projects/schematical_com/env/main.tf](../../tf/projects/schematical_com/env/main.tf) (See the `aws_wafv2_web_acl_association` resource)

