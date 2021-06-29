locals {
  linux_vm_name = var.linux_vm != null ? lookup(
    var.linux_vm, "name", null
    ) != null ? var.linux_vm.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.instance_suffix
  ])) : null

  linux_vm_os_disk_name = join(module.const.delimiter, compact([
    local.linux_vm_name,
    module.const.root_ebs_suffix
  ]))

  #terraform 1.0.0, azurerm 2.64.0 - Error: "admin_username": required field is not set
  #admin_username = try(var.linux_vm.admin_username, "admin", "no")

  #ok not for list
  # admin_username = lookup(
  #   var.linux_vm, "admin_username", null
  #   ) != null ? var.linux_vm.admin_username : lookup(
  #   var.linux_vm, "admin_ssh_key", null
  #   ) != null ? lookup(
  #   var.linux_vm.admin_ssh_key, "username", null
  # ) != null ? var.linux_vm.admin_ssh_key.username : null : null

  #ok
  # admin_username = lookup(
  #   var.linux_vm, "admin_username", null
  #   ) != null ? var.linux_vm.admin_username : lookup(
  #   var.linux_vm, "admin_ssh_key", null
  #   ) != null ? (length(var.linux_vm.admin_ssh_key) > 0 ?
  #   lookup(var.linux_vm.admin_ssh_key.0, "username", null
  # ) != null ? var.linux_vm.admin_ssh_key.0.username : null : null) : null

  admin_username = var.linux_vm != null ? lookup(
    var.linux_vm, "admin_username", null
    ) != null ? var.linux_vm.admin_username : lookup(
    var.linux_vm, "admin_ssh_key", null
    ) != null ? (length(var.linux_vm.admin_ssh_key) > 0 ? lookup(
      var.linux_vm.admin_ssh_key.0, "username", null
  ) != null ? var.linux_vm.admin_ssh_key.0.username : null : null) : null : null

  admin_password = var.linux_vm != null ? lookup(
    var.linux_vm, "admin_password", null
    ) == null ? null : lookup(
    var.linux_vm, "admin_ssh_key", null
    ) == null ? var.linux_vm.admin_password : length(
    var.linux_vm.admin_ssh_key
    ) > 0 ? lookup(
    var.linux_vm.admin_ssh_key.0, "public_key", null
  ) != null ? null : var.linux_vm.admin_password : var.linux_vm.admin_password : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
resource "azurerm_linux_virtual_machine" "this" {
  ###############################################
  count = local.enable_linux_vm

  #Required
  name                = local.linux_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name

  network_interface_ids = azurerm_network_interface.this.*.id
  #try(var.linux_vm.size, "Standard_B1ls") >>> Error: "size": required field is not set
  size = lookup(var.linux_vm, "size", null) != null ? var.linux_vm.size : "Standard_B1ls"

  os_disk {
    caching = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "caching", null
    ) != null ? var.linux_vm.os_disk.caching : "ReadWrite" : "ReadWrite"

    #DANGEROUS: storage_account_type = lookup(var.linux_vm, "os_disk", null) != null ? lookup(var.linux_vm.os_disk, "storage_account_type", "Standard_LRS") : "Standard_LRS"
    storage_account_type = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "storage_account_type", null
    ) != null ? var.linux_vm.os_disk.storage_account_type : "Standard_LRS" : "Standard_LRS"

    name = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "name", local.linux_vm_os_disk_name
    ) : local.linux_vm_os_disk_name

    disk_encryption_set_id = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "disk_encryption_set_id", null
    ) : null

    disk_size_gb = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "disk_size_gb", null
    ) : null

    write_accelerator_enabled = lookup(
      var.linux_vm, "os_disk", null
      ) != null ? lookup(
      var.linux_vm.os_disk, "write_accelerator_enabled", null
    ) : null

    # diff_disk_settings = lookup(lookup(var.linux_vm, "os_disk", null), "diff_disk_settings", null)
    dynamic "diff_disk_settings" {
      for_each = (lookup(var.linux_vm, "os_disk", null) != null ? lookup(var.linux_vm.os_disk, "diff_disk_settings", null) : null) == null ? [] : [var.linux_vm.os_disk.diff_disk_settings]
      content {
        option = diff_disk_settings.value.option
      }
    }
  }

  # Optional
  dynamic "additional_capabilities" {
    for_each = lookup(var.linux_vm, "additional_capabilities", null) == null ? [] : [var.linux_vm.additional_capabilities]
    content {
      ultra_ssd_enabled = lookup(additional_capabilities.value, "ultra_ssd_enabled", null)
    }
  }

  # try(var.linux_vm.admin_username, var.linux_vm.admin_ssh_key.0.username) >>> Error: "admin_username": required field is not set
  admin_username = local.admin_username
  admin_password = local.admin_password

  disable_password_authentication = lookup(
    var.linux_vm, "disable_password_authentication", null
  ) != null ? var.linux_vm.disable_password_authentication : local.admin_password == null

  dynamic "admin_ssh_key" {
    for_each = lookup(var.linux_vm, "admin_ssh_key", null) == null ? [] : var.linux_vm.admin_ssh_key
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  allow_extension_operations = lookup(var.linux_vm, "allow_extension_operations", null)
  availability_set_id        = lookup(var.linux_vm, "availability_set_id", null)

  dynamic "boot_diagnostics" {
    for_each = lookup(var.linux_vm, "boot_diagnostics", null) == null ? [] : [var.linux_vm.boot_diagnostics]
    content {
      storage_account_uri = lookup(boot_diagnostics.value, "storage_account_uri", null)
    }
  }

  computer_name              = lookup(var.linux_vm, "computer_name", null)
  custom_data                = lookup(var.linux_vm, "custom_data", null)
  dedicated_host_id          = lookup(var.linux_vm, "dedicated_host_id", null)
  encryption_at_host_enabled = lookup(var.linux_vm, "encryption_at_host_enabled", null)
  eviction_policy            = lookup(var.linux_vm, "eviction_policy", null)
  extensions_time_budget     = lookup(var.linux_vm, "extensions_time_budget", null)
  license_type               = lookup(var.linux_vm, "license_type", null)
  max_bid_price              = lookup(var.linux_vm, "max_bid_price", null)

  dynamic "identity" {
    for_each = lookup(var.linux_vm, "identity", null) == null ? [] : [var.linux_vm.identity]
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  dynamic "secret" {
    for_each = lookup(var.linux_vm, "secret", null) == null ? [] : var.linux_vm.secret
    content {
      certificate  = secret.value.certificate
      key_vault_id = secret.value.key_vault_id
    }
  }

  dynamic "plan" {
    for_each = lookup(var.linux_vm, "plan", null) == null ? [] : [var.linux_vm.plan]
    content {
      publisher = lookup(
        plan.value, "publisher", null
        ) != null ? plan.value.publisher : lookup(
        var.linux_vm, "source_image_reference", null
        ) != null ? lookup(
        var.linux_vm.source_image_reference, "publisher", null
      ) != null ? var.linux_vm.source_image_reference.publisher : null : null

      product = lookup(
        plan.value, "product", null
        ) != null ? plan.value.product : lookup(
        var.linux_vm, "source_image_reference", null
        ) != null ? lookup(
        var.linux_vm.source_image_reference, "offer", null
      ) != null ? var.linux_vm.source_image_reference.offer : null : null

      name = lookup(
        plan.value, "name", null
        ) != null ? plan.value.name : lookup(
        var.linux_vm, "source_image_reference", null
        ) != null ? lookup(
        var.linux_vm.source_image_reference, "sku", null
      ) != null ? var.linux_vm.source_image_reference.sku : null : null
    }
  }

  dynamic "source_image_reference" {
    for_each = lookup(var.linux_vm, "source_image_reference", null) == null ? [] : [var.linux_vm.source_image_reference]
    content {
      publisher = lookup(
        source_image_reference.value, "publisher", null
        ) != null ? source_image_reference.value.publisher : lookup(
        var.linux_vm, "plan", null
        ) != null ? lookup(
        var.linux_vm.plan, "publisher", null
      ) != null ? var.linux_vm.plan.publisher : null : null

      offer = lookup(
        source_image_reference.value, "offer", null
        ) != null ? source_image_reference.value.offer : lookup(
        var.linux_vm, "plan", null
        ) != null ? lookup(
        var.linux_vm.plan, "product", null
      ) != null ? var.linux_vm.plan.product : null : null

      sku = lookup(
        source_image_reference.value, "sku", null
        ) != null ? source_image_reference.value.sku : lookup(
        var.linux_vm, "plan", null
        ) != null ? lookup(
        var.linux_vm.plan, "name", null
      ) != null ? var.linux_vm.plan.name : null : null

      version = lookup(source_image_reference.value, "version", null)
    }
  }

  source_image_id              = lookup(var.linux_vm, "source_image_id", null)
  platform_fault_domain        = lookup(var.linux_vm, "platform_fault_domain", null)
  priority                     = lookup(var.linux_vm, "priority", null)
  provision_vm_agent           = lookup(var.linux_vm, "provision_vm_agent", null)
  proximity_placement_group_id = lookup(var.linux_vm, "proximity_placement_group_id", null)
  virtual_machine_scale_set_id = lookup(var.linux_vm, "virtual_machine_scale_set_id", null)
  zone                         = lookup(var.linux_vm, "zone", null)

  tags = merge(local.tags, {
    Name = local.linux_vm_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.linux_vm, "timeouts", null) == null ? [] : [var.linux_vm.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
