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
| [azurerm_network_ddos_protection_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ddos_protection"></a> [ddos\_protection](#input\_ddos\_protection) | n/a | <pre>object({<br>    name = optional(string)<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Flag to create all resources (optional). | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | The prefix for all environments [ROOT, DEVOPS, PROD, etc.] (required). | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure location where the Linux Virtual Machine should exist | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `""` | no |
| <a name="input_network_security_rule_increment"></a> [network\_security\_rule\_increment](#input\_network\_security\_rule\_increment) | n/a | `number` | `10` | no |
| <a name="input_network_security_rule_start"></a> [network\_security\_rule\_start](#input\_network\_security\_rule\_start) | n/a | `number` | `1000` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | n/a | <pre>object({<br>    name = optional(string)<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | <pre>map(object({<br>    name             = optional(string)<br>    address_prefixes = list(string) # optional(list(string))<br><br>    delegation = optional(list(object({<br>      name = string<br>      service_delegation = object({<br>        name    = string<br>        actions = optional(list(string))<br>      })<br>    })))<br><br>    enforce_private_link_endpoint_network_policies = optional(bool)<br>    enforce_private_link_service_network_policies  = optional(bool)<br>    service_endpoints                              = optional(list(string))<br>    service_endpoint_policy_ids                    = optional(list(string))<br><br>    network_security_rules = optional(list(string))<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags which should be assigned to all module resources | `map` | `{}` | no |
| <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network) | n/a | <pre>object({<br>    name          = optional(string)<br>    address_space = list(string)<br>    bgp_community = optional(string)<br><br>    enable_ddos_protection = optional(bool)<br><br>    dns_servers = optional(list(string))<br><br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ddos_protection"></a> [ddos\_protection](#output\_ddos\_protection) | ######################### |
| <a name="output_network_security_groups"></a> [network\_security\_groups](#output\_network\_security\_groups) | ################################# |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | ########################### |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | ############################# |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | ################# |
| <a name="output_virtual_network"></a> [virtual\_network](#output\_virtual\_network) | ######################### |
<!-- END_TF_DOCS -->