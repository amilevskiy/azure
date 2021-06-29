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
    condition = var.public_ip != null ? lookup(
      var.public_ip, "sku", null
      ) != null ? can(regex(
        "^(?i)(Basic|Standard)$",
        var.public_ip.sku
    )) : true : true

    error_message = "As of 20210621 the possible values are \"Basic\" and \"Standard\"."
  }

  validation {
    condition = var.public_ip != null ? lookup(
      var.public_ip, "allocation_method", null
      ) != null ? can(regex(
        "^(?i)(Dynamic|Static)$",
        var.public_ip.allocation_method
    )) : true : true

    error_message = "As of 20210621 the possible values are \"Static\" and \"Dynamic\"."
  }

  validation {
    condition = var.public_ip != null ? lookup(
      var.public_ip, "availability_zone", null
      ) != null ? can(regex(
        "^(?i)(Zone-Redundant|[1-3]|No-Zone)$",
        var.public_ip.availability_zone
    )) : true : true

    error_message = "As of 20210621 the possible values are \"Zone-Redundant\", \"1\", \"2\", \"3\" and \"No-Zone\"."
  }

  validation {
    condition = var.public_ip != null ? lookup(
      var.public_ip, "ip_version", null
      ) != null ? can(regex(
        "^(?i)(IPv6|IPv4)$",
        var.public_ip.ip_version
    )) : true : true

    error_message = "As of 20210621 the possible values are \"IPv6\" and \"IPv4\"."
  }

  validation {
    condition = var.public_ip != null ? lookup(
      var.public_ip, "idle_timeout_in_minutes", null
    ) != null ? 4 <= var.public_ip.idle_timeout_in_minutes && var.public_ip.idle_timeout_in_minutes <= 30 : true : true

    error_message = "As of 20210621 the value can be set between 4 and 30 minutes."
  }

  default = null
}


locals {
  public_ip_name = var.public_ip != null ? lookup(
    var.public_ip, "name", null
    ) != null ? var.public_ip.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.eip_suffix
  ])) : null

  sku         = lookup(var.public_ip, "sku", null)
  sku_defined = local.sku != null ? local.sku : "Basic"

  ip_version         = lookup(var.public_ip, "ip_version", null)
  ip_version_defined = local.ip_version != null ? local.ip_version : ""

  allocation_method = lookup(
    var.public_ip, "allocation_method", null
    ) != null ? var.public_ip.allocation_method : (
    lower(local.ip_version_defined) == "ipv6" ? "Dynamic" : (
      lower(local.sku_defined) == "standard" ? "Static" : "Dynamic"
  ))
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

  availability_zone       = lookup(var.public_ip, "availability_zone", null)
  ip_version              = local.ip_version
  idle_timeout_in_minutes = lookup(var.public_ip, "idle_timeout_in_minutes", null)
  domain_name_label       = lookup(var.public_ip, "domain_name_label", null)
  reverse_fqdn            = lookup(var.public_ip, "reverse_fqdn", null)
  public_ip_prefix_id     = lookup(var.public_ip, "public_ip_prefix_id", null)
  ip_tags                 = lookup(var.public_ip, "ip_tags", null)

  tags = merge(local.tags, {
    Name = local.public_ip_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.public_ip, "timeouts", null) == null ? [] : [var.public_ip.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
