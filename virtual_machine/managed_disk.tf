#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk
variable "managed_disk" {
  type = object({
    create_option          = optional(string) # Import, Empty, Copy, FromImage, Restore
    storage_account_type   = optional(string) # Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS
    source_uri             = optional(string) # when create_option is Import
    storage_account_id     = optional(string) # The ID of the Storage Account where the source_uri is located. Required when create_option is set to Import
    source_resource_id     = optional(string) # when create_option is Copy or Restore
    image_reference_id     = optional(string) # ID of an existing platform/marketplace disk image to copy when create_option is FromImage.
    os_type                = optional(string) # Linux, Windows if create_option Import or Copy
    disk_size_gb           = optional(number)
    disk_iops_read_write   = optional(number) # only settable for UltraSSD
    disk_mbps_read_write   = optional(number) # only settable for UltraSSD
    disk_encryption_set_id = optional(string)

    encryption_settings = optional(object({
      enabled = bool
      disk_encryption_key = optional(object({
        secret_url      = string
        source_vault_id = string
      }))
      key_encryption_key = optional(object({
        key_url         = string
        source_vault_id = string
      }))
    }))

    network_access_policy = optional(string)
    disk_access_id        = optional(string)
    tier                  = optional(string) #P1-P80 https://docs.microsoft.com/en-us/azure/virtual-machines/disks-change-performance

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))


    # azurerm_virtual_machine_data_disk_attachment options
    attachment_create_option  = optional(string) #Empty or Attach
    caching                   = optional(string) #None, ReadOnly, ReadWrite
    write_accelerator_enabled = optional(bool)

    attachment_timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? can(regex("^(?i)(Import|Empty|Copy|FromImage|Restore)$",
        var.managed_disk.create_option
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"Import\", \"Empty\", \"Copy\", \"FromImage\" and \"Restore\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.storage_account_type != null
      ? can(regex("^(?i)(Standard_LRS|Premium_LRS|StandardSSD_LRS|UltraSSD_LRS)$",
        var.managed_disk.storage_account_type
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"Standard_LRS\", \"Premium_LRS\", \"StandardSSD_LRS\" and \"UltraSSD_LRS\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? lower(var.managed_disk.create_option) == "import"
      ? var.managed_disk.source_uri != null
    ? var.managed_disk.source_uri != "" : false : true : true : true)

    error_message = "\"source_uri\" can't be empty when \"create_option\" is \"Import\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? lower(var.managed_disk.create_option) == "import"
      ? var.managed_disk.storage_account_id != null
    ? var.managed_disk.storage_account_id != "" : false : true : true : true)

    error_message = "\"storage_account_id\" can't be empty when \"create_option\" is \"Import\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? can(regex("^(?i)(Copy|Restore)$",
        var.managed_disk.create_option
      ))
      ? var.managed_disk.source_resource_id != null
    ? var.managed_disk.source_resource_id != "" : false : true : true : true)

    error_message = "\"source_resource_id\" can't be empty when \"create_option\" is \"Copy\" or \"Restore\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? lower(var.managed_disk.create_option) == "fromimage"
      ? var.managed_disk.image_reference_id != null
    ? var.managed_disk.image_reference_id != "" : false : true : true : true)

    error_message = "\"image_reference_id\" can't be empty when \"create_option\" is \"FromImage\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.create_option != null
      ? can(regex(
        "^(?i)(Import|Copy)$",
        var.managed_disk.create_option
      ))
      ? var.managed_disk.os_type != null
      ? can(regex(
        "^(?i)(Linux|Windows)$",
        var.managed_disk.os_type
    )) : false : true : true : true)

    error_message = "\"os_type\" must be \"Linux\" or \"Windows\" when \"create_option\" is \"Import\" or \"Copy\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.tier != null
      ? can(regex(
        "^(?i)P(1|2|4|6|10|15|20|30|40|50|60|70|80)$",
        var.managed_disk.tier
    )) : true : true)

    error_message = "Allowed \"tier\" values see https://docs.microsoft.com/en-us/azure/virtual-machines/disks-change-performance."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.caching != null
      ? can(regex(
        "^(?i)(None|ReadOnly|ReadWrite)$",
        var.managed_disk.caching
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"None\", \"ReadOnly\" and \"ReadWrite\"."
  }

  validation {
    condition = (var.managed_disk != null
      ? var.managed_disk.attachment_create_option != null
      ? can(regex(
        "^(?i)(Empty|Attach)$",
        var.managed_disk.attachment_create_option
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"Empty\" and \"Attach\"."
  }

  default = null
}

locals {
  managed_disk_name = join(module.const.delimiter, [
    module.const.az_prefix,
    var.env,
    var.name,
    module.const.instance_suffix,
    module.const.ebs_suffix
  ])
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk
resource "azurerm_managed_disk" "this" {
  ######################################
  count = local.enable_managed_disk

  name                = local.managed_disk_name
  resource_group_name = var.resource_group_name
  location            = var.location

  create_option          = var.managed_disk.create_option != null ? var.managed_disk.create_option : "Empty"
  storage_account_type   = var.managed_disk.storage_account_type != null ? var.managed_disk.storage_account_type : "Standard_LRS"
  source_uri             = var.managed_disk.source_uri
  source_resource_id     = var.managed_disk.source_resource_id
  storage_account_id     = var.managed_disk.storage_account_id
  image_reference_id     = var.managed_disk.image_reference_id
  os_type                = var.managed_disk.os_type
  disk_size_gb           = var.managed_disk.disk_size_gb
  disk_iops_read_write   = var.managed_disk.disk_iops_read_write
  disk_mbps_read_write   = var.managed_disk.disk_mbps_read_write
  disk_encryption_set_id = var.managed_disk.disk_encryption_set_id
  network_access_policy  = var.managed_disk.network_access_policy
  disk_access_id         = var.managed_disk.disk_access_id
  tier                   = var.managed_disk.tier

  dynamic "encryption_settings" {
    for_each = var.managed_disk.encryption_settings != null ? [var.managed_disk.encryption_settings] : []
    content {
      enabled = encryption_settings.value.enabled

      dynamic "disk_encryption_key" {
        for_each = encryption_settings.value.disk_encryption_key != null ? [encryption_settings.value.disk_encryption_key] : []
        content {
          secret_url      = disk_encryption_key.value.secret_url
          source_vault_id = disk_encryption_key.value.source_vault_id
        }
      }

      dynamic "key_encryption_key" {
        for_each = encryption_settings.value.key_encryption_key != null ? [encryption_settings.value.key_encryption_key] : []
        content {
          key_url         = key_encryption_key.value.key_url
          source_vault_id = key_encryption_key.value.source_vault_id
        }
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.managed_disk_name
  })

  dynamic "timeouts" {
    for_each = var.managed_disk.timeouts != null ? [var.managed_disk.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment
resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  ##############################################################
  count = local.enable_managed_disk

  virtual_machine_id = element(coalescelist(
    azurerm_linux_virtual_machine.this.*.id, azurerm_windows_virtual_machine.this.*.id
  ), 0)

  managed_disk_id           = azurerm_managed_disk.this[count.index].id
  create_option             = var.managed_disk.attachment_create_option
  caching                   = var.managed_disk.caching != null ? var.managed_disk.caching : "ReadWrite"
  lun                       = count.index
  write_accelerator_enabled = var.managed_disk.write_accelerator_enabled

  dynamic "timeouts" {
    for_each = var.managed_disk.attachment_timeouts != null ? [var.managed_disk.attachment_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
