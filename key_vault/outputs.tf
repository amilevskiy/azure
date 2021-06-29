#https://www.terraform.io/docs/configuration/outputs.html

####################
output "key_vault" {
  ##################
  value = azurerm_key_vault.this[0]
}

##########################
output "access_policies" {
  ########################
  value = azurerm_key_vault_access_policy.this
}

#######################
output "certificates" {
  #####################
  value = azurerm_key_vault_certificate.this
}
