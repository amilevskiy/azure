variable "virtual_network" {
  type = object({
    name          = optional(string)
    address_space = list(string)
    bgp_community = optional(string)

    enable_ddos_protection = optional(bool)

    dns_servers = optional(list(string))

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
  enable_virtual_network = var.enable && var.virtual_network != null ? 1 : 0

  virtual_network_name = var.virtual_network != null ? lookup(
    var.virtual_network, "name", null
    ) != null ? var.virtual_network.name : join(module.const.delimiter, [
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.vnet_suffix
  ]) : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "this" {
  #########################################
  count = local.enable_virtual_network

  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = local.resource_group_name
  address_space       = lookup(var.virtual_network, "address_space", null)
  bgp_community       = lookup(var.virtual_network, "bgp_community", null)

  dynamic "ddos_protection_plan" {
    for_each = azurerm_network_ddos_protection_plan.this.*.id
    content {
      id     = ddos_protection_plan.value
      enable = true
    }
  }

  dns_servers = lookup(var.virtual_network, "dns_servers", null)

  tags = merge(local.tags, {
    Name = local.virtual_network_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.virtual_network, "timeouts", null) == null ? [] : [var.virtual_network.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  depends_on = [
    azurerm_resource_group.this
  ]
}
