variable "ddos_protection" {
  type = object({
    name = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  default = null
}

locals {
  enable_ddos_protection = var.enable && var.ddos_protection != null ? 1 : 0

  ddos_protection_name = (var.ddos_protection != null
    ? var.ddos_protection.name != null
    ? var.ddos_protection.name
    : join(module.const.delimiter, [
      local.resource_group_name,
      module.const.ddos_protection_suffix
  ]) : null)
}


#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan
resource "azurerm_network_ddos_protection_plan" "this" {
  ######################################################
  count = local.enable_ddos_protection

  name                = local.ddos_protection_name
  location            = var.location
  resource_group_name = local.resource_group_name

  tags = merge(local.tags, {
    Name = local.ddos_protection_name
  })

  dynamic "timeouts" {
    for_each = var.ddos_protection.timeouts != null ? [var.ddos_protection.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azurerm_resource_group.this
  ]
}
