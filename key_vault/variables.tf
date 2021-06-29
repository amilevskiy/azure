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
  description = " (Required) The Azure location where resources should exist"
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which resources should be created"
}

variable "tenant_id" {
  default     = ""
  description = "(Optional) The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault."
}


variable "tags" {
  default     = {}
  description = "(Optional) A mapping of tags which should be assigned to all module resources"
}
