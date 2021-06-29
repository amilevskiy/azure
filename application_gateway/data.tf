#https://www.terraform.io/docs/configuration/locals.html
locals {
  ######

  enable                        = var.enable ? 1 : 0
  enable_application_gateway    = var.enable && var.application_gateway != null ? 1 : 0
  enable_public_ip              = var.enable && var.public_ip != null ? 1 : 0
  enable_network_security_group = local.enable_application_gateway > 0 && var.network_security_group != null ? 1 : 0

  tags = var.enable ? merge({
    Environment = var.env != "" ? var.env : null
    Terraform   = "true"
  }, var.tags) : {}
}
