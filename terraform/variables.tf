variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "esic-lab"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}