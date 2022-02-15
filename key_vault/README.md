<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_const"></a> [const](#module\_const) | github.com/amilevskiy/const | v0.1.11 |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_certificate.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) | resource |
| [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | n/a | <pre>map(object({<br>    object_id      = optional(string)<br>    application_id = optional(string)<br><br>    grant_all_permissions = optional(bool)<br><br>    certificate_permissions = optional(list(string))<br>    key_permissions         = optional(list(string))<br>    secret_permissions      = optional(list(string))<br>    storage_permissions     = optional(list(string))<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | n/a | <pre>map(object({<br>    certificate = optional(object({<br>      contents = string<br>      password = optional(string)<br>    }))<br><br>    certificate_policy = optional(object({<br>      issuer_parameters = optional(object({<br>        name = optional(string) # Self or Unknown<br>      }))<br><br>      key_properties = optional(object({<br>        curve      = optional(string) # P-256, P-256K, P-384, and P-521<br>        exportable = optional(bool)<br>        key_size   = optional(number)<br>        key_type   = optional(string)<br>        reuse_key  = optional(bool)<br>      }))<br><br>      lifetime_action = optional(object({<br>        action = object({<br>          action_type = string # AutoRenew and EmailContacts<br>        })<br><br>        trigger = object({<br>          days_before_expiry  = number<br>          lifetime_percentage = number<br>        })<br>      }))<br><br>      secret_properties = optional(object({<br>        content_type = optional(string) # application/x-pkcs12 for a PFX or application/x-pem-file for a PEM<br>      }))<br><br>      x509_certificate_properties = optional(object({<br>        extended_key_usage = list(string)<br><br>        key_usage = list(string) # cRLSign, dataEncipherment, decipherOnly, digitalSignature, encipherOnly, keyAgreement, keyCertSign, keyEncipherment and nonRepudiation<br><br>        subject = string<br><br>        subject_alternative_names = optional(object({<br>          emails    = optional(list(string))<br>          dns_names = optional(list(string))<br>          upns      = optional(list(string))<br>        }))<br><br>        validity_in_months = number<br>      }))<br>    }))<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Flag to create all resources (optional). | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | The prefix for all environments [ROOT, DEVOPS, PROD, etc.] (required). | `string` | `""` | no |
| <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault) | n/a | <pre>object({<br>    name = optional(string)<br><br>    sku_name = optional(string)<br><br>    access_policy = optional(list(object({<br>      tenant_id               = optional(string)<br>      object_id               = optional(string)<br>      application_id          = optional(string)<br>      certificate_permissions = optional(list(string))<br>      key_permissions         = optional(list(string))<br>      secret_permissions      = optional(list(string))<br>      storage_permissions     = optional(list(string))<br>    })))<br><br>    enabled_for_deployment          = optional(bool)<br>    enabled_for_disk_encryption     = optional(bool)<br>    enabled_for_template_deployment = optional(bool)<br>    enable_rbac_authorization       = optional(bool)<br>    purge_protection_enabled        = optional(bool)<br>    soft_delete_retention_days      = optional(number)<br><br>    contact = optional(list(object({<br>      email = string<br>      name  = optional(string)<br>      phone = optional(string)<br>    })))<br><br>    network_acls = optional(object({<br>      bypass                     = optional(string)<br>      default_action             = optional(string)<br>      ip_rules                   = optional(list(string))<br>      virtual_network_subnet_ids = optional(list(string))<br>    }))<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure location where resources should exist | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `""` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the Resource Group in which resources should be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags which should be assigned to all module resources | `map` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Optional) The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_policies"></a> [access\_policies](#output\_access\_policies) | ######################### |
| <a name="output_certificates"></a> [certificates](#output\_certificates) | ###################### |
| <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault) | ################### |
<!-- END_TF_DOCS -->