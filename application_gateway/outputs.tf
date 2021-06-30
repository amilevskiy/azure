#https://www.terraform.io/docs/configuration/outputs.html

##############################
output "application_gateway" {
  ############################
  value = try(azurerm_application_gateway.this[0], null)
}

#################################
output "network_security_group" {
  ###############################
  value = try(azurerm_network_security_group.this[0], null)
}

####################
output "public_ip" {
  ##################
  value = try(azurerm_public_ip.this[0], null)
}
