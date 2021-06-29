#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "this" {
  ###################################
  count = var.enable && (var.tenant_id == "" || length(local.empty_policies) > 0) ? 1 : 0
}

#https://www.terraform.io/docs/configuration/locals.html
locals {
  ######

  enable           = var.enable ? 1 : 0
  enable_key_vault = var.enable && var.key_vault != null ? 1 : 0

  certificates    = local.enable_key_vault > 0 ? var.certificates : {}
  access_policies = local.enable_key_vault > 0 ? var.access_policies : {}

  empty_policies = [
    for k, v in var.access_policies : true if k == ""
  ]

  tags = var.enable ? merge({
    Environment = var.env != "" ? var.env : null
    Terraform   = "true"
  }, var.tags) : {}
}
