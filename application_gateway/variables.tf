variable "env" {
  default     = ""
  description = "The prefix for all environments [ROOT, DEVOPS, PROD, etc.] (required)."
}

variable "name" {
  default = ""
}


variable "enable" {
  default     = false
  description = "Flag to create all resources (optional)."
}


variable "location" {
  type        = string
  description = " (Required) The Azure location where the Linux Virtual Machine should exist"
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which the Linux Virtual Machine should be exist"
}

variable "tags" {
  default     = {}
  description = "(Optional) A mapping of tags which should be assigned to all module resources"
}
