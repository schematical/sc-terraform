module "ses" {
  source = "../../modules/bluefox-email"
  domains = ["splittestgpt.com"]
}