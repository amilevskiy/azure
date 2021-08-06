variable "linux_vm" {
  type = object({
    name = optional(string)

    os_disk = optional(object({
      caching                   = optional(string)
      storage_account_type      = optional(string)
      disk_encryption_set_id    = optional(string)
      disk_size_gb              = optional(number)
      name                      = optional(string)
      write_accelerator_enabled = optional(bool)
      diff_disk_settings = optional(object({
        option = string
      }))
    }))

    additional_capabilities = optional(object({
      ultra_ssd_enabled = optional(bool)
    }))

    admin_username = optional(string)
    admin_password = optional(string)
    admin_ssh_key = optional(list(object({
      username   = string
      public_key = string
    })))
    disable_password_authentication = optional(bool)

    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    plan = optional(object({
      publisher = optional(string)
      product   = optional(string)
      name      = optional(string)
    }))

    source_image_reference = optional(object({
      publisher = optional(string)
      offer     = optional(string)
      sku       = optional(string)
      version   = optional(string)
    }))

    secret = optional(list(object({
      key_vault_id = string
      certificate = object({
        url = string
      })
    })))

    size                         = optional(string) # https://docs.microsoft.com/en-us/azure/virtual-machines/linux/compute-benchmark-scores
    custom_data                  = optional(string)
    platform_fault_domain        = optional(number)
    allow_extension_operations   = optional(bool)
    availability_set_id          = optional(string)
    computer_name                = optional(string)
    dedicated_host_id            = optional(string)
    encryption_at_host_enabled   = optional(bool)
    eviction_policy              = optional(string)
    extensions_time_budget       = optional(string)
    license_type                 = optional(string)
    max_bid_price                = optional(number)
    source_image_id              = optional(string)
    priority                     = optional(string)
    provision_vm_agent           = optional(bool)
    proximity_placement_group_id = optional(string)
    virtual_machine_scale_set_id = optional(string)
    zone                         = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  })


  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "diff_disk_settings", null
      ) != null ? lookup(
      var.linux_vm.diff_disk_settings, "option", null
    ) != null ? lower(var.linux_vm.diff_disk_settings.option) == "local" : true : true : true

    error_message = "As of 20210621 the only supported value is \"Local\"."
  }

  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "identity", null
      ) != null ? lookup(
      var.linux_vm.identity, "type", null
      ) != null ? can(regex(
        "^(SystemAssigned|UserAssigned|SystemAssigned, UserAssigned)$",
        var.linux_vm.identity.type
    )) : true : true : true

    error_message = "As of 20210621 the only possible values are \"SystemAssigned\", \"UserAssigned\" and \"SystemAssigned, UserAssigned\"."
  }

  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "license_type", null
      ) != null ? can(regex(
        "^(RHEL_BYOS|SLES_BYOS)$",
        var.linux_vm.license_type
    )) : true : true

    error_message = "As of 20210621 the only possible values are \"RHEL_BYOS\" and \"SLES_BYOS\"."
  }

  #xor!
  validation {
    condition = var.linux_vm != null ? (
      lookup(var.linux_vm, "admin_password", null) == null && lookup(var.linux_vm, "admin_ssh_key", null) != null
      ) || (
      lookup(var.linux_vm, "admin_password", null) != null && lookup(var.linux_vm, "admin_ssh_key", null) == null
    ) : true

    error_message = "As of 20210621 one of either admin_password or admin_ssh_key must be specified."
  }

  #xor!
  validation {
    condition = var.linux_vm != null ? (
      lookup(var.linux_vm, "source_image_id", null) == null && lookup(var.linux_vm, "source_image_reference", null) != null
      ) || (
      lookup(var.linux_vm, "source_image_id", null) != null && lookup(var.linux_vm, "source_image_reference", null) == null
    ) : true

    error_message = "As of 20210621 one of either source_image_id or source_image_reference must be set."
  }

  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "priority", null
      ) != null ? can(regex(
        "^(?i)(Regular|Spot)$",
        var.linux_vm.priority
    )) : true : true

    error_message = "As of 20210621 the only possible values are \"Regular\" and \"Spot\"."
  }

  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "eviction_policy", null
      ) != null ? var.linux_vm.eviction_policy != "" ? lookup(
      var.linux_vm, "priority", null
      ) != null ? lower(
      var.linux_vm.priority
    ) == "spot" : false : true : true : true

    error_message = "As of 20210621 eviction_policy can only be configured when priority is set to \"Spot\"."
  }

  validation {
    condition = var.linux_vm != null ? lookup(
      var.linux_vm, "eviction_policy", null
    ) != null ? lower(var.linux_vm.eviction_policy) == "deallocate" : true : true

    error_message = "As of 20210621 the only supported value is \"Deallocate\"."
  }

  default = null
}
