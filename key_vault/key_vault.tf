variable "key_vault" {
  type = object({
    name = optional(string)

    sku_name = optional(string)

    access_policy = optional(list(object({
      tenant_id               = optional(string)
      object_id               = optional(string)
      application_id          = optional(string)
      certificate_permissions = optional(list(string))
      key_permissions         = optional(list(string))
      secret_permissions      = optional(list(string))
      storage_permissions     = optional(list(string))
    })))

    enabled_for_deployment          = optional(bool)
    enabled_for_disk_encryption     = optional(bool)
    enabled_for_template_deployment = optional(bool)
    enable_rbac_authorization       = optional(bool)
    purge_protection_enabled        = optional(bool)
    soft_delete_retention_days      = optional(number)

    contact = optional(list(object({
      email = string
      name  = optional(string)
      phone = optional(string)
    })))

    network_acls = optional(object({
      bypass                     = optional(string)
      default_action             = optional(string)
      ip_rules                   = optional(list(string))
      virtual_network_subnet_ids = optional(list(string))
    }))

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  validation {
    condition = var.key_vault != null ? lookup(
      var.key_vault, "sku_name", null
      ) != null ? can(regex(
        "^(?i)(Standard|Premium)$",
        var.key_vault.sku_name
    )) : true : true

    error_message = "As of 20210621 the only possible values are \"Standard\" and \"Premium\"."
  }

  validation {
    condition = var.key_vault != null ? lookup(
      var.key_vault, "soft_delete_retention_days", null
      ) != null ? (
      7 <= var.key_vault.soft_delete_retention_days && var.key_vault.soft_delete_retention_days <= 90
    ) : true : true

    error_message = "As of 20210621 the value can be between 7 and 90."
  }

  validation {
    condition = var.key_vault != null ? lookup(
      var.key_vault, "name", null
      ) != null ? can(regex(
        "^[-a-zA-Z0-9]{3,24}$",
        var.key_vault.name
    )) : true : true

    error_message = "As of 20210621 the name may only contain alphanumeric characters and dashes and must be between 3-24 chars."
  }

  default = null
}

locals {
  tenant_id = element(coalescelist(
    var.tenant_id != "" ? [var.tenant_id] : [],
    data.azurerm_client_config.this.*.object_id,
    [""]
  ), 0)

  key_vault_name = var.key_vault != null ? lookup(
    var.key_vault, "name", null
    ) != null ? var.key_vault.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.key_vault_suffix
  ])) : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
resource "azurerm_key_vault" "this" {
  ###################################
  count = local.enable_key_vault

  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id = local.tenant_id

  sku_name = lookup(var.key_vault, "sku_name", null) != null ? lower(var.key_vault.sku_name) : "standard"

  enabled_for_deployment          = lookup(var.key_vault, "enabled_for_deployment", null)
  enabled_for_disk_encryption     = lookup(var.key_vault, "enabled_for_disk_encryption", null)
  enabled_for_template_deployment = lookup(var.key_vault, "enabled_for_template_deployment", null)
  enable_rbac_authorization       = lookup(var.key_vault, "enable_rbac_authorization", null)
  purge_protection_enabled        = lookup(var.key_vault, "purge_protection_enabled", null)
  soft_delete_retention_days      = lookup(var.key_vault, "soft_delete_retention_days", null)

  dynamic "access_policy" {
    for_each = lookup(var.key_vault, "access_policy", null) == null ? [] : var.key_vault.access_policy
    content {
      tenant_id               = lookup(access_policy.value, "tenant_id", local.tenant_id)
      object_id               = access_policy.value.object_id
      application_id          = lookup(access_policy.value, "application_id", null)
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", null)
      key_permissions         = lookup(access_policy.value, "key_permissions", null)
      secret_permissions      = lookup(access_policy.value, "secret_permissions", null)
      storage_permissions     = lookup(access_policy.value, "storage_permissions", null)
    }
  }

  dynamic "contact" {
    for_each = lookup(var.key_vault, "contact", null) == null ? [] : var.key_vault.contact
    content {
      email = contact.value.email
      name  = lookup(contact.value, "name", null)
      phone = lookup(contact.value, "phone", null)
    }
  }

  dynamic "network_acls" {
    for_each = lookup(var.key_vault, "network_acls", null) == null ? [] : [var.key_vault.network_acls]
    content {
      bypass                     = lookup(network_acls.value, "bypass", "None")
      default_action             = lookup(network_acls.value, "default_action", "Deny")
      ip_rules                   = lookup(network_acls.value, "ip_rules", null)
      virtual_network_subnet_ids = lookup(network_acls.value, "value.virtual_network_subnet_ids", null)
    }
  }

  tags = merge(local.tags, {
    Name = local.key_vault_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.key_vault, "timeouts", null) == null ? [] : [var.key_vault.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
