#https://www.terraform.io/docs/configuration/locals
locals {
  ######

  enable = var.enable && (
    var.linux_vm == null && var.windows_vm != null ||
    var.linux_vm != null && var.windows_vm == null
  ) ? 1 : 0

  enable_linux_vm               = var.enable && var.linux_vm != null ? 1 : 0
  enable_windows_vm             = var.enable && var.windows_vm != null ? 1 : 0
  enable_network_interface      = var.enable && var.network_interface != null ? 1 : 0
  enable_public_ip              = var.enable && var.public_ip != null ? 1 : 0
  enable_managed_disk           = var.enable && var.managed_disk != null ? 1 : 0
  enable_vm_extension           = var.enable && var.vm_extension != null ? 1 : 0
  enable_network_security_group = var.enable && var.network_security_group != null ? 1 : 0

  tags = var.enable ? merge({
    Environment = var.env != "" ? var.env : null
    Terraform   = "true"
  }, var.tags) : {}
}
