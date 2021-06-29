#https://www.terraform.io/docs/configuration/outputs.html

###################
output "linux_vm" {
  #################
  value = local.enable_linux_vm > 0 ? azurerm_linux_virtual_machine.this : []
}

#####################
output "windows_vm" {
  ###################
  value = local.enable_windows_vm > 0 ? azurerm_windows_virtual_machine.this : []
}

#######################
output "managed_disk" {
  #####################
  value = local.enable_managed_disk > 0 ? azurerm_managed_disk.this[0] : null
}

##################################
output "managed_disk_attachment" {
  ################################
  value = local.enable_managed_disk > 0 ? azurerm_virtual_machine_data_disk_attachment.this[0] : null
}

############################
output "network_interface" {
  ##########################
  value = local.enable_network_interface > 0 ? azurerm_network_interface.this[0] : null
}

####################
output "public_ip" {
  ##################
  value = local.enable_public_ip > 0 ? azurerm_public_ip.this[0] : null
}

#######################
output "vm_extension" {
  #####################
  value = local.enable_vm_extension > 0 ? azurerm_virtual_machine_extension.this[0] : null
}
