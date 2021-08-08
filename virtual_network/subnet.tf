variable "subnets" {
  type = map(object({
    name             = optional(string)
    address_prefixes = list(string) # optional(list(string))

    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })))

    enforce_private_link_endpoint_network_policies = optional(bool)
    enforce_private_link_service_network_policies  = optional(bool)
    service_endpoints                              = optional(list(string))
    service_endpoint_policy_ids                    = optional(list(string))

    network_security_rules = optional(list(string))

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  }))

  default = null
}

locals {
  subnets = var.enable && var.virtual_network != null && var.subnets != null ? var.subnets : {}
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "this" {
  ################################
  for_each = local.subnets

  name                 = each.value.name != null ? each.value.name : each.key
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name

  address_prefixes = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation != null ? each.value.delegation : []
    content {
      name = delegation.value.name

      dynamic "service_delegation" {
        for_each = [delegation.value.service_delegation]
        content {
          name    = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }

  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = each.value.enforce_private_link_service_network_policies

  service_endpoints = (each.value.service_endpoints != null
    ? length(each.value.service_endpoints) > 0
    ? each.value.service_endpoints
  : null : null)

  service_endpoint_policy_ids = (each.value.service_endpoint_policy_ids != null
    ? length(each.value.service_endpoint_policy_ids) > 0
    ? each.value.service_endpoint_policy_ids
  : null : null)

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
