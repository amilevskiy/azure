variable "network_security_group" {
  type = object({
    name = optional(string)

    security_rules = optional(list(string))

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
  network_security_group_name = (var.network_security_group != null
    ? var.network_security_group.name != null
    ? var.network_security_group.name
    : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.sg_suffix
  ])) : null)
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "this" {
  ################################################
  count = local.enable_network_security_group

  name                = local.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.network_security_group.security_rules != null ? [
      for v in var.network_security_group.security_rules : split(" ", replace(v, "/\\s+/", " "))
    ] : null

    content {
      description                  = lower(join(" ", slice(security_rule.value, 0, 3)))
      priority                     = security_rule.key * var.network_security_rule_increment + var.network_security_rule_start
      name                         = security_rule.value[0]
      direction                    = security_rule.value[1]
      access                       = security_rule.value[2]
      protocol                     = security_rule.value[3]
      source_address_prefix        = security_rule.value[4] == "*" ? "*" : null
      source_address_prefixes      = security_rule.value[4] != "*" ? split(",", security_rule.value[4]) : null
      source_port_range            = security_rule.value[5] == "*" ? "*" : null
      source_port_ranges           = security_rule.value[5] != "*" ? split(",", security_rule.value[5]) : null
      destination_address_prefix   = security_rule.value[6] == "*" ? "*" : null
      destination_address_prefixes = security_rule.value[6] != "*" ? split(",", security_rule.value[6]) : null
      destination_port_range       = security_rule.value[7] == "*" ? "*" : null
      destination_port_ranges      = security_rule.value[7] != "*" ? split(",", security_rule.value[7]) : null
    }
  }

  tags = merge(local.tags, {
    Name = local.network_security_group_name
  })

  dynamic "timeouts" {
    for_each = var.network_security_group.timeouts != null ? [var.network_security_group.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
resource "azurerm_network_interface_security_group_association" "this" {
  ######################################################################
  count = local.enable_network_security_group * local.enable_network_interface

  network_interface_id      = azurerm_network_interface.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this[count.index].id
}
