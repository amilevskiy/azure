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

  # list - OK
  validation {
    condition = (var.network_interface != null
      ? var.network_interface.ip_configuration != null
      ? alltrue([for v in var.network_interface.ip_configuration : can(regex(
        "^(?i)(Dynamic|Static)$",
        v.private_ip_address_allocation,
      )) if v.private_ip_address_allocation != null])
    : true : true)

    error_message = "As of 20210621 the possible values are \"Dynamic\" and \"Static\"."
  }

  default = null
}

locals {
  network_interface_name = (var.network_interface != null
    ? var.network_interface.name != null
    ? var.network_interface.name
    : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.eni_suffix
  ])) : null)
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "this" {
  ###########################################
  count = local.enable_network_interface

  name                = local.network_interface_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "ip_configuration" {
    for_each = var.network_interface.ip_configuration != null ? var.network_interface.ip_configuration : []
    content {
      name = join(module.const.delimiter, compact([
        module.const.az_prefix,
        var.env,
        var.name,
        module.const.eni_suffix,
        length(var.network_interface.ip_configuration) > 1 ? ip_configuration.key : "",
        module.const.ip_config_suffix
      ]))

      subnet_id = ip_configuration.value.subnet_id

      private_ip_address_version = ip_configuration.value.private_ip_address_version

      private_ip_address_allocation = (
        ip_configuration.value.private_ip_address_allocation != null
        ? ip_configuration.value.private_ip_address_allocation : "Dynamic"
      )

      private_ip_address = (
        ip_configuration.value.private_ip_address_allocation != null
        ? lower(ip_configuration.value.private_ip_address_allocation) == "static"
        ? ip_configuration.value.private_ip_address
      : null : null)

      public_ip_address_id = ip_configuration.key == 0 && local.enable_public_ip > 0 ? azurerm_public_ip.this[count.index].id : null
      primary              = ip_configuration.key == 0
    }
  }

  dns_servers                   = var.network_interface.dns_servers
  enable_ip_forwarding          = var.network_interface.enable_ip_forwarding
  enable_accelerated_networking = var.network_interface.enable_accelerated_networking
  internal_dns_name_label       = var.network_interface.internal_dns_name_label

  tags = merge(local.tags, {
    Name = local.network_interface_name
  })

  dynamic "timeouts" {
    for_each = var.network_interface.timeouts != null ? [var.network_interface.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
