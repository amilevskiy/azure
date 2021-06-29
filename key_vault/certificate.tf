variable "certificates" {
  type = map(object({
    certificate = optional(object({
      contents = string
      password = optional(string)
    }))

    certificate_policy = optional(object({
      issuer_parameters = optional(object({
        name = optional(string) # Self or Unknown
      }))

      key_properties = optional(object({
        curve      = optional(string) # P-256, P-256K, P-384, and P-521
        exportable = optional(bool)
        key_size   = optional(number)
        key_type   = optional(string)
        reuse_key  = optional(bool)
      }))

      lifetime_action = optional(object({
        action = object({
          action_type = string # AutoRenew and EmailContacts
        })

        trigger = object({
          days_before_expiry  = number
          lifetime_percentage = number
        })
      }))

      secret_properties = optional(object({
        content_type = optional(string) # application/x-pkcs12 for a PFX or application/x-pem-file for a PEM
      }))

      x509_certificate_properties = optional(object({
        extended_key_usage = list(string)

        key_usage = list(string) # cRLSign, dataEncipherment, decipherOnly, digitalSignature, encipherOnly, keyAgreement, keyCertSign, keyEncipherment and nonRepudiation

        subject = string

        subject_alternative_names = optional(object({
          emails    = optional(list(string))
          dns_names = optional(list(string))
          upns      = optional(list(string))
        }))

        validity_in_months = number
      }))
    }))

    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  }))

  default = null
}


#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate
resource "azurerm_key_vault_certificate" "this" {
  ###############################################
  for_each = local.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.this[0].id

  dynamic "certificate" {
    for_each = lookup(each.value, "certificate", null) == null ? [] : [each.value.certificate]
    content {
      contents = certificate.value.contents
      password = lookup(certificate.value, "password", null)
    }
  }

  certificate_policy {
    issuer_parameters {
      # name = lookup(each.value.certificate_policy.issuer_parameters, "name", null) != null ? each.value.certificate_policy.issuer_parameters.name : "Unknown"
      name = try(each.value.certificate_policy.issuer_parameters.name, "Unknown")
    }

    key_properties {
      curve      = can(each.value.certificate_policy.key_properties.curve) ? each.value.certificate_policy.key_properties.curve : null
      exportable = try(each.value.certificate_policy.key_properties.exportable, false)
      key_size   = try(each.value.certificate_policy.key_properties.key_size, 2048)
      key_type   = try(each.value.certificate_policy.key_properties.key_type, "RSA")
      reuse_key  = try(each.value.certificate_policy.key_properties.reuse_key, false)
    }

    dynamic "lifetime_action" {
      for_each = lookup(
        each.value, "certificate_policy", null
        ) == null ? [] : lookup(
        each.value.certificate_policy, "lifetime_action", null
        ) == null ? [] : [
        each.value.certificate_policy.lifetime_action
      ]

      content {
        action {
          action_type = lifetime_action.value.action.action_type
        }

        trigger {
          days_before_expiry = can(
            lifetime_action.value.trigger.days_before_expiry
          ) ? lifetime_action.value.trigger.days_before_expiry : null
          lifetime_percentage = can(
            lifetime_action.value.trigger.lifetime_percentage
          ) ? lifetime_action.value.trigger.lifetime_percentage : null
        }
      }
    }

    secret_properties {
      content_type = try(each.value.certificate_policy.secret_properties.content_type, "application/x-pkcs12")
    }

    dynamic "x509_certificate_properties" {
      for_each = lookup(
        each.value, "certificate_policy", null
        ) == null ? [] : lookup(
        each.value.certificate_policy, "x509_certificate_properties", null
        ) == null ? [] : [
        each.value.certificate_policy.x509_certificate_properties
      ]

      content {
        extended_key_usage = lookup(x509_certificate_properties.value, "extended_key_usage", null)
        key_usage          = x509_certificate_properties.value.key_usage
        subject            = x509_certificate_properties.value.subject

        dynamic "subject_alternative_names" {
          for_each = lookup(x509_certificate_properties.value, "subject_alternative_names", null) == null ? [] : [x509_certificate_properties.value.subject_alternative_names]
          content {
            emails    = lookup(subject_alternative_names.value, "emails", null)
            dns_names = lookup(subject_alternative_names.value, "dns_names", null)
            upns      = lookup(subject_alternative_names.value, "upns", null)
          }
        }

        validity_in_months = x509_certificate_properties.value.validity_in_months
      }
    }
  }

  tags = merge(local.tags, {
    Name = each.key
  })

  dynamic "timeouts" {
    for_each = lookup(each.value, "timeouts", null) == null ? [] : [each.value.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  depends_on = [azurerm_key_vault_access_policy.this]
}
