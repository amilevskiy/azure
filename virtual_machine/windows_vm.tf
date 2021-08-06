locals {
  windows_vm_name = var.windows_vm != null ? lookup(
    var.windows_vm, "name", null
    ) != null ? var.windows_vm.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.instance_suffix
  ])) : null

  windows_vm_os_disk_name = join(module.const.delimiter, compact([
    local.windows_vm_name,
    module.const.root_ebs_suffix
  ]))
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
resource "azurerm_windows_virtual_machine" "this" {
  #################################################
  count = local.enable_windows_vm

  #Required
  name                = local.windows_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name

  admin_username = lookup(var.windows_vm, "admin_username", null)
  admin_password = lookup(var.windows_vm, "admin_password", null)

  network_interface_ids = azurerm_network_interface.this.*.id
  size                  = lookup(var.windows_vm, "size", null) != null ? var.windows_vm.size : "Standard_B1ls"

  os_disk {
    caching = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "caching", null
    ) != null ? var.windows_vm.os_disk.caching : "ReadWrite" : "ReadWrite"

    storage_account_type = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "storage_account_type", null
    ) != null ? var.windows_vm.os_disk.storage_account_type : "Standard_LRS" : "Standard_LRS"

    name = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "name", local.windows_vm_os_disk_name
    ) : local.windows_vm_os_disk_name

    disk_encryption_set_id = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "disk_encryption_set_id", null
    ) : null

    disk_size_gb = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "disk_size_gb", null
    ) : null

    write_accelerator_enabled = lookup(
      var.windows_vm, "os_disk", null
      ) != null ? lookup(
      var.windows_vm.os_disk, "write_accelerator_enabled", null
    ) : null

    dynamic "diff_disk_settings" {
      for_each = (lookup(var.windows_vm, "os_disk", null) != null ? lookup(var.windows_vm.os_disk, "diff_disk_settings", null) : null) == null ? [] : [var.windows_vm.os_disk.diff_disk_settings]
      content {
        option = diff_disk_settings.value.option
      }
    }
  }

  # Optional
  dynamic "additional_capabilities" {
    for_each = lookup(var.windows_vm, "additional_capabilities", null) == null ? [] : [var.windows_vm.additional_capabilities]
    content {
      ultra_ssd_enabled = lookup(additional_capabilities.value, "ultra_ssd_enabled", null)
    }
  }

  dynamic "additional_unattend_content" {
    for_each = lookup(var.windows_vm, "additional_unattend_content", null) == null ? [] : var.windows_vm.additional_unattend_content
    content {
      content = lookup(additional_unattend_content.value, "content", null)
      setting = lookup(additional_unattend_content.value, "setting", null)
    }
  }

  allow_extension_operations = lookup(var.windows_vm, "allow_extension_operations", null)
  availability_set_id        = lookup(var.windows_vm, "availability_set_id", null)

  dynamic "boot_diagnostics" {
    for_each = lookup(var.windows_vm, "boot_diagnostics", null) == null ? [] : [var.windows_vm.boot_diagnostics]
    content {
      storage_account_uri = lookup(boot_diagnostics.value, "storage_account_uri", null)
    }
  }

  computer_name              = lookup(var.windows_vm, "computer_name", null)
  custom_data                = lookup(var.windows_vm, "custom_data", null)
  dedicated_host_id          = lookup(var.windows_vm, "dedicated_host_id", null)
  enable_automatic_updates   = lookup(var.windows_vm, "enable_automatic_updates", null)
  encryption_at_host_enabled = lookup(var.windows_vm, "encryption_at_host_enabled", null)
  eviction_policy            = lookup(var.windows_vm, "eviction_policy", null)
  extensions_time_budget     = lookup(var.windows_vm, "extensions_time_budget", null)

  dynamic "identity" {
    for_each = lookup(var.windows_vm, "identity", null) == null ? [] : [var.windows_vm.identity]
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  license_type  = lookup(var.windows_vm, "license_type", null)
  max_bid_price = lookup(var.windows_vm, "max_bid_price", null)
  patch_mode    = lookup(var.windows_vm, "patch_mode", null)

  dynamic "plan" {
    for_each = lookup(var.windows_vm, "plan", null) == null ? [] : [var.windows_vm.plan]
    content {
      publisher = lookup(
        plan.value, "publisher", null
        ) != null ? plan.value.publisher : lookup(
        var.windows_vm, "source_image_reference", null
        ) != null ? lookup(
        var.windows_vm.source_image_reference, "publisher", null
      ) != null ? var.windows_vm.source_image_reference.publisher : null : null

      product = lookup(
        plan.value, "product", null
        ) != null ? plan.value.product : lookup(
        var.windows_vm, "source_image_reference", null
        ) != null ? lookup(
        var.windows_vm.source_image_reference, "offer", null
      ) != null ? var.windows_vm.source_image_reference.offer : null : null

      name = lookup(
        plan.value, "name", null
        ) != null ? plan.value.name : lookup(
        var.windows_vm, "source_image_reference", null
        ) != null ? lookup(
        var.windows_vm.source_image_reference, "sku", null
      ) != null ? var.windows_vm.source_image_reference.sku : null : null
    }
  }

  platform_fault_domain        = lookup(var.windows_vm, "platform_fault_domain", null)
  priority                     = lookup(var.windows_vm, "priority", null)
  provision_vm_agent           = lookup(var.windows_vm, "provision_vm_agent", null)
  proximity_placement_group_id = lookup(var.windows_vm, "proximity_placement_group_id", null)

  dynamic "secret" {
    for_each = lookup(var.windows_vm, "secret", null) == null ? [] : var.windows_vm.secret
    content {
      key_vault_id = secret.value.key_vault_id
      dynamic "certificate" {
        for_each = secret.value.certificate != null ? [secret.value.certificate] : []
        content {
          store = certificate.value.store
          url   = certificate.value.url
        }
      }
    }
  }

  source_image_id = lookup(var.windows_vm, "source_image_id", null)

  dynamic "source_image_reference" {
    for_each = lookup(var.windows_vm, "source_image_reference", null) == null ? [] : [var.windows_vm.source_image_reference]
    content {
      publisher = lookup(
        source_image_reference.value, "publisher", null
        ) != null ? source_image_reference.value.publisher : lookup(
        var.windows_vm, "plan", null
        ) != null ? lookup(
        var.windows_vm.plan, "publisher", null
      ) != null ? var.windows_vm.plan.publisher : null : null

      offer = lookup(
        source_image_reference.value, "offer", null
        ) != null ? source_image_reference.value.offer : lookup(
        var.windows_vm, "plan", null
        ) != null ? lookup(
        var.windows_vm.plan, "product", null
      ) != null ? var.windows_vm.plan.product : null : null

      sku = lookup(
        source_image_reference.value, "sku", null
        ) != null ? source_image_reference.value.sku : lookup(
        var.windows_vm, "plan", null
        ) != null ? lookup(
        var.windows_vm.plan, "name", null
      ) != null ? var.windows_vm.plan.name : null : null

      version = lookup(source_image_reference.value, "version", null)
    }
  }

  timezone                     = lookup(var.windows_vm, "timezone", null)
  virtual_machine_scale_set_id = lookup(var.windows_vm, "virtual_machine_scale_set_id", null)

  dynamic "winrm_listener" {
    for_each = lookup(var.windows_vm, "winrm_listener", null) == null ? [] : var.windows_vm.winrm_listener
    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

  zone = lookup(var.windows_vm, "zone", null)

  tags = merge(local.tags, {
    Name = local.windows_vm_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.windows_vm, "timeouts", null) == null ? [] : [var.windows_vm.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
