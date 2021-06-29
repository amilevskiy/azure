variable "vm_extension" {
  type = object({
    publisher                  = optional(string)
    type                       = optional(string)
    type_handler_version       = optional(string)
    auto_upgrade_minor_version = optional(bool)
    settings                   = optional(string)
    protected_settings         = optional(string)

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
  vm_extension_name = join(module.const.delimiter, [
    module.const.az_prefix,
    var.env,
    var.name,
    module.const.instance_suffix,
    module.const.vm_extension_suffix,
  ])
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension
resource "azurerm_virtual_machine_extension" "this" {
  ###################################################
  count = local.enable_vm_extension

  name = local.vm_extension_name

  virtual_machine_id = element(coalescelist(
    azurerm_linux_virtual_machine.this.*.id, azurerm_windows_virtual_machine.this.*.id
  ), 0)

  publisher                  = lookup(var.vm_extension, "publisher", null) != null ? var.vm_extension.publisher : "Microsoft.Azure.Extensions"
  type                       = lookup(var.vm_extension, "type", null) != null ? var.vm_extension.type : "CustomScript"
  type_handler_version       = lookup(var.vm_extension, "type_handler_version", null) != null ? var.vm_extension.type_handler_version : "2.0"
  auto_upgrade_minor_version = lookup(var.vm_extension, "auto_upgrade_minor_version", null)

  settings           = lookup(var.vm_extension, "settings", null)
  protected_settings = lookup(var.vm_extension, "protected_settings", null)

  tags = merge(local.tags, {
    Name = local.vm_extension_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.vm_extension, "timeouts", null) == null ? [] : [var.vm_extension.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
