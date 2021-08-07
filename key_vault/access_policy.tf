variable "access_policies" {
  type = map(object({
    object_id      = optional(string)
    application_id = optional(string)

    grant_all_permissions = optional(bool)

    certificate_permissions = optional(list(string))
    key_permissions         = optional(list(string))
    secret_permissions      = optional(list(string))
    storage_permissions     = optional(list(string))

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  }))

  default = null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy
resource "azurerm_key_vault_access_policy" "this" {
  #################################################
  for_each = local.access_policies

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = local.tenant_id

  object_id = (
    each.value.object_id
    ) != null ? each.value.object_id : coalesce(
    each.key, join("", data.azurerm_client_config.this.*.object_id)
  )

  application_id = each.value.application_id

  # not working
  # certificate_permissions = try(each.value.certificate_permissions,
  #  lookup(each.value, "grant_all_permissions", null) != null ? each.value.grant_all_permissions ? [
  # "Backup", "Update", ] : [] : [])

  certificate_permissions = (each.value.certificate_permissions != null
    ? each.value.certificate_permissions
    : each.value.grant_all_permissions != null
    ? each.value.grant_all_permissions ? [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update",
  ] : null : null)

  key_permissions = (each.value.key_permissions != null
    ? each.value.key_permissions
    : each.value.grant_all_permissions != null
    ? each.value.grant_all_permissions ? [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
  ] : null : null)

  secret_permissions = (each.value.secret_permissions != null
    ? each.value.secret_permissions
    : each.value.grant_all_permissions != null
    ? each.value.grant_all_permissions ? [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
  ] : null : null)

  storage_permissions = (each.value.storage_permissions != null
    ? each.value.secret_permissions
    : each.value.grant_all_permissions != null
    ? each.value.grant_all_permissions ? [
      "Backup",
      "Delete",
      "DeleteSAS",
      "Get",
      "GetSAS",
      "List",
      "ListSAS",
      "Purge",
      "Recover",
      "RegenerateKey",
      "Restore",
      "Set",
      "SetSAS",
      "Update",
  ] : null : null)

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
