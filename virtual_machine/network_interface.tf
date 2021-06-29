#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
variable "network_interface" {
  type = object({
    name = optional(string)

    ip_configuration = list(object({
      name                          = optional(string)
      subnet_id                     = optional(string)
      private_ip_address_version    = optional(string)
      private_ip_address_allocation = optional(string) # Dynamic, Static
      private_ip_address            = optional(string)
      # primary                     = optional(bool)
      # public_ip_address_id        = optional(string)
    }))

    dns_servers                   = optional(list(string))
    enable_ip_forwarding          = optional(bool)
    enable_accelerated_networking = optional(bool)
    internal_dns_name_label       = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  validation {
    condition = var.network_interface != null ? lookup(
      var.network_interface, "private_ip_address_allocation", null
      ) != null ? can(regex(
        "^(?i)(Dynamic|Static)$",
        var.network_interface.private_ip_address_allocation
    )) : true : true

    error_message = "As of 20210621 the possible values are \"Dynamic\" and \"Static\"."
  }

  default = null
}

locals {
  network_interface_name = var.network_interface != null ? lookup(
    var.network_interface, "name", null
    ) != null ? var.network_interface.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.eni_suffix
  ])) : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "this" {
  ###########################################
  count = local.enable_network_interface

  name                = local.network_interface_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "ip_configuration" {
    for_each = lookup(var.network_interface, "ip_configuration", null) == null ? [] : var.network_interface.ip_configuration
    content {
      name = join(module.const.delimiter, compact([
        module.const.az_prefix,
        var.env,
        var.name,
        module.const.eni_suffix,
        length(var.network_interface.ip_configuration) > 1 ? ip_configuration.key : "",
        module.const.ip_config_suffix
      ]))

      subnet_id = lookup(ip_configuration.value, "subnet_id", null)

      private_ip_address_version = lookup(ip_configuration.value, "private_ip_address_version", null)

      private_ip_address_allocation = lookup(
        ip_configuration.value, "private_ip_address_allocation", null
      ) != null ? ip_configuration.value.private_ip_address_allocation : "Dynamic"

      private_ip_address = lookup(
        ip_configuration.value, "private_ip_address_allocation", null
        ) != null ? lower(ip_configuration.value.private_ip_address_allocation) == "static" ? lookup(
        ip_configuration.value, "private_ip_address", null
      ) : null : null

      public_ip_address_id = ip_configuration.key == 0 && local.enable_public_ip > 0 ? azurerm_public_ip.this[count.index].id : null
      primary              = ip_configuration.key == 0
    }
  }

  dns_servers                   = lookup(var.network_interface, "dns_servers", null)
  enable_ip_forwarding          = lookup(var.network_interface, "enable_ip_forwarding", null)
  enable_accelerated_networking = lookup(var.network_interface, "enable_accelerated_networking", null)
  internal_dns_name_label       = lookup(var.network_interface, "internal_dns_name_label", null)

  tags = merge(local.tags, {
    Name = local.network_interface_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.network_interface, "timeouts", null) == null ? [] : [var.network_interface.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
