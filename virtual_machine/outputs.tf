#https://www.terraform.io/docs/configuration/outputs

###################################
#output "managed_disk_attachment" {
#  ################################
#  value = try(azurerm_virtual_machine_data_disk_attachment.this[0], null)
#}

################################
output "linux_virtual_machine" {
  ##############################
  value = try(azurerm_linux_virtual_machine.this[0], null)
}

##################################
output "windows_virtual_machine" {
  ################################
  value = try(azurerm_windows_virtual_machine.this[0], null)
}

#######################
output "managed_disk" {
  #####################
  value = try(azurerm_managed_disk.this[0], null)
}

############################
output "network_interface" {
  ##########################
  value = try(azurerm_network_interface.this[0], null)
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

####################################
output "virtual_machine_extension" {
  ##################################
  value = try(azurerm_virtual_machine_extension.this[0], null)
}
