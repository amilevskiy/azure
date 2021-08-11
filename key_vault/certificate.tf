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
    for_each = each.value.certificate != null ? [each.value.certificate] : []
    content {
      contents = certificate.value.contents
      password = certificate.value.password
    }
  }

  certificate_policy {
    issuer_parameters {
      name = try(each.value.certificate_policy.issuer_parameters.name, "Unknown")
    }

    key_properties {
      curve      = try(each.value.certificate_policy.key_properties.curve, null)
      exportable = try(each.value.certificate_policy.key_properties.exportable, true)
      key_size   = try(each.value.certificate_policy.key_properties.key_size, 2048)
      key_type   = try(each.value.certificate_policy.key_properties.key_type, "RSA")
      reuse_key  = try(each.value.certificate_policy.key_properties.reuse_key, false)
    }

    dynamic "lifetime_action" {
      for_each = each.value.certificate_policy != null ? each.value.certificate_policy.lifetime_action != null ? [
        each.value.certificate_policy.lifetime_action
      ] : [] : []

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
      for_each = each.value.certificate_policy != null ? each.value.certificate_policy.x509_certificate_properties != null ? [
        each.value.certificate_policy.x509_certificate_properties
      ] : [] : []

      content {
        extended_key_usage = x509_certificate_properties.value.extended_key_usage
        key_usage          = x509_certificate_properties.value.key_usage
        subject            = x509_certificate_properties.value.subject

        dynamic "subject_alternative_names" {
          for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
          content {
            emails    = subject_alternative_names.value.emails
            dns_names = subject_alternative_names.value.dns_names
            upns      = subject_alternative_names.value.upns
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
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }

  depends_on = [azurerm_key_vault_access_policy.this]
}
