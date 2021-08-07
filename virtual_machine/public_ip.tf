#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
variable "public_ip" {
  type = object({
    name = optional(string)

    sku                     = optional(string)
    allocation_method       = optional(string)
    availability_zone       = optional(string)
    ip_version              = optional(string)
    idle_timeout_in_minutes = optional(number)
    domain_name_label       = optional(string)
    reverse_fqdn            = optional(string)
    public_ip_prefix_id     = optional(string)
    ip_tags                 = optional(map(string))

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  validation {
    condition = (var.public_ip != null
      ? var.public_ip.sku != null
      ? can(regex(
        "^(?i)(Basic|Standard)$",
        var.public_ip.sku
    )) : true : true)

    error_message = "As of 20210621 the possible values are \"Basic\" and \"Standard\"."
  }

  validation {
    condition = (var.public_ip != null
      ? var.public_ip.allocation_method != null
      ? can(regex(
        "^(?i)(Dynamic|Static)$",
        var.public_ip.allocation_method
    )) : true : true)

    error_message = "As of 20210621 the possible values are \"Static\" and \"Dynamic\"."
  }

  validation {
    condition = (var.public_ip != null
      ? var.public_ip.availability_zone != null
      ? can(regex(
        "^(?i)(Zone-Redundant|[1-3]|No-Zone)$",
        var.public_ip.availability_zone
    )) : true : true)

    error_message = "As of 20210621 the possible values are \"Zone-Redundant\", \"1\", \"2\", \"3\" and \"No-Zone\"."
  }

  validation {
    condition = (var.public_ip != null
      ? var.public_ip.ip_version != null
      ? can(regex(
        "^(?i)(IPv6|IPv4)$",
        var.public_ip.ip_version
    )) : true : true)

    error_message = "As of 20210621 the possible values are \"IPv6\" and \"IPv4\"."
  }

  validation {
    condition = (var.public_ip != null
      ? var.public_ip.idle_timeout_in_minutes != null
      ? 4 <= var.public_ip.idle_timeout_in_minutes && var.public_ip.idle_timeout_in_minutes <= 30
    : true : true)

    error_message = "As of 20210621 the value can be set between 4 and 30 minutes."
  }

  default = null
}


locals {
  public_ip_name = (var.public_ip != null
    ? var.public_ip.name != null
    ? var.public_ip.name
    : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.eip_suffix
  ])) : null)

  sku         = var.public_ip.sku
  sku_defined = local.sku != null ? local.sku : "Basic"

  ip_version         = var.public_ip.ip_version
  ip_version_defined = local.ip_version != null ? local.ip_version : ""

  allocation_method = (var.public_ip.allocation_method != null
    ? var.public_ip.allocation_method : lower(local.ip_version_defined) == "ipv6"
    ? "Dynamic" : lower(local.sku_defined) == "standard"
    ? "Static" : "Dynamic"
  )
}


#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "this" {
  ###################################
  count = local.enable_public_ip

  name                = local.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = local.sku
  allocation_method = local.allocation_method

  availability_zone       = var.public_ip.availability_zone
  ip_version              = local.ip_version
  idle_timeout_in_minutes = var.public_ip.idle_timeout_in_minutes
  domain_name_label       = var.public_ip.domain_name_label
  reverse_fqdn            = var.public_ip.reverse_fqdn
  public_ip_prefix_id     = var.public_ip.public_ip_prefix_id
  ip_tags                 = var.public_ip.ip_tags

  tags = merge(local.tags, {
    Name = local.public_ip_name
  })

  dynamic "timeouts" {
    for_each = var.public_ip.timeouts != null ? [var.public_ip.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
