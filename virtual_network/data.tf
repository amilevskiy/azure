#https://www.terraform.io/docs/configuration/locals
locals {
  ######

  enable = var.enable ? 1 : 0

  tags = var.enable ? merge({
    Environment = var.env != "" ? var.env : null
    Terraform   = "true"
  }, var.tags) : {}
}
