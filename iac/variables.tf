variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-dfaustino-dvfinlab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "finalproj"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
  default     = {
    environment = "cicd"
    owner       = "davidf"
  }
}

variable "vm2_private_ip" {
  description = "Static private IP address for VM2"
  type        = string
  default     = "10.0.1.100"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into vm1 (e.g. 0.0.0.0/0 for testing)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "postgres_port" {
  description = "Port for PostgreSQL"
  type        = number
  default     = 5432
}
