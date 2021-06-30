#https://www.terraform.io/docs/configuration/outputs.html

##############################
output "resource_group_name" {
  ############################
  value = local.resource_group_name
}

############################
output "resource_group_id" {
  ##########################
  value = local.enable_resource_group > 0 ? azurerm_resource_group.this[0].id : null
}

##########################
output "ddos_protection" {
  ########################
  value = try(azurerm_network_ddos_protection_plan.this[0], null)
}

##########################
output "virtual_network" {
  ########################
  value = try(azurerm_virtual_network.this[0], null)
}

##################
output "subnets" {
  ################
  value = try(azurerm_subnet.this, null)
}

##################################
output "network_security_groups" {
  ################################
  value = try(azurerm_network_security_group.this, null)
}
