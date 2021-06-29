variable "network_security_group" {
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
  network_security_group_name = var.network_security_group != null ? lookup(
    var.network_security_group, "name", null
    ) != null ? var.network_security_group.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.sg_suffix
  ])) : null

  #Error: Invalid for_each argument
  #local.subnet_ids is a list of dynamic, known only after apply
  # subnet_ids = local.enable_network_security_group > 0 ? lookup(
  #   var.application_gateway, "gateway_ip_configuration", null
  #   ) != null ? distinct(compact([
  #     for k, v in var.application_gateway.gateway_ip_configuration : v.subnet_id
  # ])) : [] : []
  association_count = local.enable_network_security_group > 0 ? lookup(
    var.application_gateway, "gateway_ip_configuration", null
  ) != null ? length(var.application_gateway.gateway_ip_configuration) : 0 : 0
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "this" {
  ################################################
  count = local.enable_network_security_group

  name                = local.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    description                = local.network_security_group_name
    priority                   = 1000
    name                       = "All_inbound_traffic_in_one_rule"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges = concat([
      for k, v in var.application_gateway.frontend_port : v.port
    ], ["65200-65535"])
  }

  tags = merge(local.tags, {
    Name = local.network_security_group_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.network_security_group, "timeouts", null) == null ? [] : [var.network_security_group.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "this" {
  ###################################################################
  # for_each = toset(local.subnet_ids)
  count = local.association_count

  # subnet_id = element([
  #   for k, v in var.application_gateway.gateway_ip_configuration : v.subnet_id
  # ], count.index)
  subnet_id = var.application_gateway.gateway_ip_configuration[count.index]["subnet_id"]

  network_security_group_id = azurerm_network_security_group.this[0].id
}
