locals {
  linux_vm_name = var.linux_vm != null ? (
    var.linux_vm.name
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

  admin_username = var.linux_vm != null ? (
    var.linux_vm.admin_username
    ) != null ? var.linux_vm.admin_username : (
    var.linux_vm.admin_ssh_key
    ) != null ? (length(var.linux_vm.admin_ssh_key) > 0 ? (
      var.linux_vm.admin_ssh_key.0.username
  ) != null ? var.linux_vm.admin_ssh_key.0.username : null : null) : null : null

  admin_password = var.linux_vm != null ? (
    var.linux_vm.admin_password
    ) == null ? null : (
    var.linux_vm.admin_ssh_key
    ) == null ? var.linux_vm.admin_password : length(
    var.linux_vm.admin_ssh_key
    ) > 0 ? (
    var.linux_vm.admin_ssh_key.0.public_key
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
  size                  = var.linux_vm.size != null ? var.linux_vm.size : "Standard_B1ls"

  #avoid `dynamic "os_disk" {}` to allow not pass `os_disk = {}` at all
  os_disk {
    caching = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.caching != null
      ? var.linux_vm.os_disk.caching
      : "ReadWrite" : "ReadWrite"
    )

    storage_account_type = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.storage_account_type != null
      ? var.linux_vm.os_disk.storage_account_type
      : "Standard_LRS" : "Standard_LRS"
    )

    name = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.name != null
      ? var.linux_vm.os_disk.name
      : local.linux_vm_os_disk_name : local.linux_vm_os_disk_name
    )

    disk_encryption_set_id = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.disk_encryption_set_id
    : null)

    disk_size_gb = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.disk_size_gb
    : null)

    write_accelerator_enabled = (var.linux_vm.os_disk != null
      ? var.linux_vm.os_disk.write_accelerator_enabled
    : null)

    dynamic "diff_disk_settings" {
      for_each = (var.linux_vm.os_disk != null
        ? var.linux_vm.os_disk.diff_disk_settings != null
        ? [var.linux_vm.os_disk.diff_disk_settings]
      : [] : [])
      content {
        option = diff_disk_settings.value.option
      }
    }
  }

  # Optional
  dynamic "additional_capabilities" {
    for_each = var.linux_vm.additional_capabilities != null ? [var.linux_vm.additional_capabilities] : []
    content {
      ultra_ssd_enabled = additional_capabilities.value.ultra_ssd_enabled
    }
  }

  admin_username = local.admin_username
  admin_password = local.admin_password

  disable_password_authentication = (
    var.linux_vm.disable_password_authentication
  ) != null ? var.linux_vm.disable_password_authentication : local.admin_password == null

  dynamic "admin_ssh_key" {
    for_each = var.linux_vm.admin_ssh_key != null ? var.linux_vm.admin_ssh_key : []
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  allow_extension_operations = var.linux_vm.allow_extension_operations
  availability_set_id        = var.linux_vm.availability_set_id

  dynamic "boot_diagnostics" {
    for_each = var.linux_vm.boot_diagnostics != null ? [var.linux_vm.boot_diagnostics] : []
    content {
      storage_account_uri = boot_diagnostics.value.storage_account_uri
    }
  }

  computer_name              = var.linux_vm.computer_name
  custom_data                = var.linux_vm.custom_data
  dedicated_host_id          = var.linux_vm.dedicated_host_id
  encryption_at_host_enabled = var.linux_vm.encryption_at_host_enabled
  eviction_policy            = var.linux_vm.eviction_policy
  extensions_time_budget     = var.linux_vm.extensions_time_budget
  license_type               = var.linux_vm.license_type
  max_bid_price              = var.linux_vm.max_bid_price

  dynamic "identity" {
    for_each = var.linux_vm.identity != null ? [var.linux_vm.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "secret" {
    for_each = var.linux_vm.secret != null ? var.linux_vm.secret : []
    content {
      key_vault_id = secret.value.key_vault_id
      dynamic "certificate" {
        for_each = secret.value.certificate != null ? [secret.value.certificate] : []
        content {
          url = certificate.value.url
        }
      }
    }
  }

  dynamic "plan" {
    for_each = var.linux_vm.plan != null ? [var.linux_vm.plan] : []
    content {
      publisher = (plan.value.publisher != null
        ? plan.value.publisher
        : var.linux_vm.source_image_reference != null
      ? var.linux_vm.source_image_reference.publisher : null)

      product = (plan.value.product != null
        ? plan.value.product
        : var.linux_vm.source_image_reference != null
      ? var.linux_vm.source_image_reference.offer : null)

      name = (plan.value.name != null
        ? plan.value.name
        : var.linux_vm.source_image_reference != null
      ? var.linux_vm.source_image_reference.sku : null)
    }
  }

  dynamic "source_image_reference" {
    for_each = var.linux_vm.source_image_reference != null ? [var.linux_vm.source_image_reference] : []
    content {
      publisher = (source_image_reference.value.publisher != null
        ? source_image_reference.value.publisher
        : var.linux_vm.plan != null
      ? var.linux_vm.plan.publisher : null)

      offer = (source_image_reference.value.offer != null
        ? source_image_reference.value.offer
        : var.linux_vm.plan != null
      ? var.linux_vm.plan.product : null)

      sku = (source_image_reference.value.sku != null
        ? source_image_reference.value.sku
        : var.linux_vm.plan != null
      ? var.linux_vm.plan.name : null)

      version = source_image_reference.value.version
    }
  }

  source_image_id              = var.linux_vm.source_image_id
  platform_fault_domain        = var.linux_vm.platform_fault_domain
  priority                     = var.linux_vm.priority
  provision_vm_agent           = var.linux_vm.provision_vm_agent
  proximity_placement_group_id = var.linux_vm.proximity_placement_group_id
  virtual_machine_scale_set_id = var.linux_vm.virtual_machine_scale_set_id
  zone                         = var.linux_vm.zone

  tags = merge(local.tags, {
    Name = local.linux_vm_name
  })

  dynamic "timeouts" {
    for_each = var.linux_vm.timeouts != null ? [var.linux_vm.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
