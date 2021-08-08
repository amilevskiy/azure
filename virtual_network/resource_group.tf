variable "resource_group_name" {
  type    = string
  default = null
}

variable "resource_group" {
  type = object({
    name = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  #xor!
  #validation {
  #  condition = ((
  #    var.resource_group == null && var.resource_group_name != null
  #    ) || (
  #    var.resource_group != null && var.resource_group_name == null
  #  ))

  #  error_message = "The resource_group_name and resource_group are mutually exclusive."
  #}

  default = null
}

locals {
  enable_resource_group = var.enable && (
    var.resource_group_name == null || var.resource_group_name == ""
  ) && var.resource_group != null ? 1 : 0

  #ok
  resource_group_name = (var.resource_group_name != null && var.resource_group_name != ""
    ? var.resource_group_name
    : var.resource_group != null
    ? var.resource_group.name != null
    ? var.resource_group.name
    : join(module.const.delimiter, [
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.resource_group_suffix
  ]) : null)

  # Error: "name": required field is not set
  # resource_group_name = local.enable_resource_group > 0 ? lookup(
  #   var.resource_group, "name", join(module.const.delimiter, [
  #     module.const.az_prefix,
  #     var.env,
  #     var.name,
  #     module.const.resource_group_suffix
  # ])) : var.resource_group_name

  # Error: "name": required field is not set
  # module "bcp" {
  #   resource_group_name = join("", azurerm_resource_group.this.*.name)
  #   resource_group = {}
  # }
  # resource_group_name = local.external_resource_group_enabled ? var.resource_group_name : var.resource_group != null ? lookup(
  #   var.resource_group, "name", join(module.const.delimiter, compact([
  #     module.const.az_prefix,
  #     var.env,
  #     var.name,
  #     module.const.resource_group_suffix
  # ]))) : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "this" {
  ########################################
  count = local.enable_resource_group

  name     = local.resource_group_name
  location = var.location

  tags = merge(local.tags, {
    Name = local.resource_group_name
  })

  dynamic "timeouts" {
    for_each = var.resource_group.timeouts != null ? [var.resource_group.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
