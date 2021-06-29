variable "subnets" {
  type = map(any)
  # type = map(object({
  #   address_prefixes = list(string) # optional(list(string))

  #   delegation = optional(list(object({
  #     name = string
  #     service_delegation = object({
  #       name    = string
  #       actions = optional(list(string))
  #     })
  #   })))

  #   enforce_private_link_endpoint_network_policies = optional(bool)
  #   enforce_private_link_service_network_policies  = optional(bool)
  #   service_endpoints                              = optional(list(string))
  #   service_endpoint_policy_ids                    = optional(list(string))

  #   timeouts = optional(object({
  #     create = optional(string)
  #     update = optional(string)
  #     read   = optional(string)
  #     delete = optional(string)
  #   }))
  # }))

  default = null
}

locals {
  subnets = var.enable && var.virtual_network != null && var.subnets != null ? var.subnets : {}
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "this" {
  ################################
  for_each = local.subnets

  name                 = lookup(each.value, "name", null) != null ? each.value.name : each.key
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name

  address_prefixes = each.value.address_prefixes

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) == null ? [] : each.value.delegation
    content {
      name = delegation.value.name

      dynamic "service_delegation" {
        for_each = [delegation.value.service_delegation]
        content {
          name    = service_delegation.value.name
          actions = lookup(service_delegation.value, "actions", null)
        }
      }
    }
  }

  enforce_private_link_endpoint_network_policies = lookup(
    each.value, "enforce_private_link_endpoint_network_policies", null
  )

  enforce_private_link_service_network_policies = lookup(
    each.value, "enforce_private_link_service_network_policies", null
  )

  service_endpoints = lookup(
    each.value, "service_endpoints", null
    ) != null ? length(
    each.value.service_endpoints
  ) > 0 ? each.value.service_endpoints : null : null

  service_endpoint_policy_ids = lookup(
    each.value, "service_endpoint_policy_ids", null
    ) != null ? length(
    each.value.service_endpoint_policy_ids
  ) > 0 ? each.value.service_endpoint_policy_ids : null : null

  dynamic "timeouts" {
    for_each = lookup(each.value, "timeouts", null) == null ? [] : [each.value.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
