#https://www.terraform.io/docs/configuration/outputs.html

####################
output "key_vault" {
  ##################
  value = try(azurerm_key_vault.this[0], null)
}

##########################
output "access_policies" {
  ########################
  value = try(azurerm_key_vault_access_policy.this, null)
}

#######################
output "certificates" {
  #####################
  value = try(azurerm_key_vault_certificate.this, null)
}
