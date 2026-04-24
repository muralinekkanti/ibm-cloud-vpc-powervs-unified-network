variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "zone" {
  description = "Power VS zone"
  type        = string
}

variable "network_cidr" {
  description = "CIDR block for Power VS private network"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for Power VS network"
  type        = list(string)
  default     = ["9.9.9.9", "1.1.1.1"]
}

variable "instance_count" {
  description = "Number of Power VS instances to create"
  type        = number
  default     = 2
}

variable "image_name" {
  description = "Name of the Power VS image (e.g., RHEL8-SP4, SLES15-SP3)"
  type        = string
}

variable "processor_type" {
  description = "Processor type (shared, dedicated, or capped)"
  type        = string
  default     = "shared"
  validation {
    condition     = contains(["shared", "dedicated", "capped"], var.processor_type)
    error_message = "Processor type must be 'shared', 'dedicated', or 'capped'."
  }
}

variable "system_type" {
  description = "System type (s922, e980, s1022, etc.)"
  type        = string
  default     = "s922"
}

variable "cores" {
  description = "Number of cores per instance"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in GB per instance"
  type        = number
  default     = 16
}

variable "storage_size" {
  description = "Storage size in GB per instance"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (tier1 or tier3)"
  type        = string
  default     = "tier3"
  validation {
    condition     = contains(["tier1", "tier3"], var.storage_type)
    error_message = "Storage type must be 'tier1' or 'tier3'."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  default     = ""
}

variable "tags" {
  description = "List of tags"
  type        = list(string)
  default     = []
}