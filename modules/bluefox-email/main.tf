module "ses" {
  for_each = toset(var.domains)
  source = "./domain"
  domain = each.value
  region = var.region
}