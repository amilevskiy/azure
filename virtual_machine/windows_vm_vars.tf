variable "windows_vm" {
  type = object({
    name = optional(string)

    admin_username = string
    admin_password = string

    size = optional(string)

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

    additional_unattend_content = optional(list(object({
      content = string
      setting = string
    })))

    allow_extension_operations = optional(bool)
    availability_set_id        = optional(string)

    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))

    computer_name              = optional(string)
    custom_data                = optional(string)
    dedicated_host_id          = optional(string)
    enable_automatic_updates   = optional(bool)
    encryption_at_host_enabled = optional(bool)
    eviction_policy            = optional(string)
    extensions_time_budget     = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    license_type  = optional(string)
    max_bid_price = optional(number)
    patch_mode    = optional(string)

    plan = optional(object({
      publisher = optional(string)
      product   = optional(string)
      name      = optional(string)
    }))

    platform_fault_domain        = optional(number)
    priority                     = optional(string)
    provision_vm_agent           = optional(bool)
    proximity_placement_group_id = optional(string)

    secret = optional(list(object({
      key_vault_id = string
      certificate = object({
        store = string
        url   = string
      })
    })))

    source_image_id = optional(string)

    source_image_reference = optional(object({
      publisher = optional(string)
      offer     = optional(string)
      sku       = optional(string)
      version   = optional(string)
    }))

    timezone                     = optional(string) # https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
    virtual_machine_scale_set_id = optional(string)

    winrm_listener = optional(list(object({
      protocol        = string
      certificate_url = optional(string)
    })))

    zone = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  })

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.os_disk != null
      ? var.windows_vm.os_disk.diff_disk_settings != null
      ? var.windows_vm.os_disk.diff_disk_settings.option != null
      ? lower(var.windows_vm.os_disk.diff_disk_settings.option) == "local"
    : true : true : true : true)

    error_message = "As of 20210621 the only supported value is \"Local\"."
  }

  #list - OK
  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.additional_unattend_content != null
      ? alltrue([for v in var.windows_vm.additional_unattend_content : can(regex(
        "^(AutoLogon|FirstLogonCommands)$",
        v.setting,
      )) if v.setting != null])
    : true : true)

    error_message = "As of 20210621 the only possible values are \"AutoLogon\", \"FirstLogonCommands\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.identity != null
      ? var.windows_vm.identity.type != null
      ? can(regex(
        "^(SystemAssigned|UserAssigned|SystemAssigned, UserAssigned)$",
        var.windows_vm.identity.type
    )) : true : true : true)

    error_message = "As of 20210621 the only possible values are \"SystemAssigned\", \"UserAssigned\" and \"SystemAssigned, UserAssigned\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.license_type != null
      ? can(regex(
        "^(None|Windows_Client|Windows_Server)$",
        var.windows_vm.license_type
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"None\", \"Windows_Client\" and \"Windows_Server\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.patch_mode != null
      ? can(regex(
        "^(Manual|AutomaticByOS|AutomaticByPlatform)$",
        var.windows_vm.patch_mode
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"Manual\", \"AutomaticByOS\" and AutomaticByPlatform\"."
  }

  #xor!
  validation {
    condition = var.windows_vm != null ? (
      var.windows_vm.source_image_id == null && var.windows_vm.source_image_reference != null
      ) || (
      var.windows_vm.source_image_id != null && var.windows_vm.source_image_reference == null
    ) : true

    error_message = "As of 20210621 one of either source_image_id or source_image_reference must be set."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.priority != null
      ? can(regex(
        "^(?i)(Regular|Spot)$",
        var.windows_vm.priority
    )) : true : true)

    error_message = "As of 20210621 the only possible values are \"Regular\" and \"Spot\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.eviction_policy != null
      ? var.windows_vm.eviction_policy != ""
      ? var.windows_vm.priority != null
      ? lower(var.windows_vm.priority) == "spot"
    : false : true : true : true)

    error_message = "As of 20210621 eviction_policy can only be configured when priority is set to \"Spot\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.eviction_policy != null
      ? lower(var.windows_vm.eviction_policy) == "deallocate"
    : true : true)

    error_message = "As of 20210621 the only supported value is \"Deallocate\"."
  }

  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.winrm_listener != null
      ? var.windows_vm.winrm_listener.protocol != null
      ? can(regex(
        "^(Http|Https)$",
        var.windows_vm.winrm_listener.protocol
    )) : true : true : true)

    error_message = "As of 20210621 the only possible values are \"Http\" and \"Https\"."
  }

  #стал list! -> distinct([for])==[true]?
  validation {
    condition = (var.windows_vm != null
      ? var.windows_vm.winrm_listener != null
      ? var.windows_vm.winrm_listener.protocol != null
      ? lower(var.windows_vm.winrm_listener.protocol) == "https"
      ? var.windows_vm.winrm_listener.certificate_url != null
      ? var.windows_vm.winrm_listener.certificate_url != ""
    : false : true : true : true : true)

    error_message = "As of 20210621 certificate_url must be specified when protocol is set to \"Https\"."
  }

  default = null
}
