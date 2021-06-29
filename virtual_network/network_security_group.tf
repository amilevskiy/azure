locals {
  network_security_groups = {
    for k, v in local.subnets : k => [
      for vv in v.network_security_rules : split(" ", replace(vv, "/\\s+/", " "))
    ] if length(v.network_security_rules) > 0
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "this" {
  ################################################
  for_each = local.network_security_groups

  name = join(module.const.delimiter, [
    azurerm_subnet.this[each.key].name, module.const.sg_suffix
  ])

  location            = var.location
  resource_group_name = local.resource_group_name

  dynamic "security_rule" {
    for_each = each.value
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
    Name = join(module.const.delimiter, [
      azurerm_subnet.this[each.key].name, module.const.sg_suffix
    ])
  })
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "this" {
  ###################################################################
  for_each = local.network_security_groups

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
