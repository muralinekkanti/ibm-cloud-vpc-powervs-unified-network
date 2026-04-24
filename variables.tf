# ==============================================================================
# Authentication Variables
# ==============================================================================

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key for authentication"
  type        = string
  sensitive   = true
}

# ==============================================================================
# General Configuration
# ==============================================================================

variable "region" {
  description = "IBM Cloud region for VPC resources"
  type        = string
  default     = "us-south"
  validation {
    condition     = can(regex("^(us-south|us-east|eu-gb|eu-de|jp-tok|au-syd|jp-osa|br-sao|ca-tor)$", var.region))
    error_message = "Region must be a valid IBM Cloud region."
  }
}

variable "resource_group" {
  description = "Name of the IBM Cloud resource group"
  type        = string
  default     = "Default"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "dev-infra"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "List of tags to apply to all resources"
  type        = list(string)
  default     = ["terraform", "dev-environment"]
}
# ==============================================================================
# SSH Key Configuration
# ==============================================================================

variable "vpc_ssh_key_name" {
  description = "Name of the SSH key for VPC instances"
  type        = string
  default     = "example-key"
}

variable "power_vs_ssh_key_name" {
  description = "Name of the SSH key for Power VS instances"
  type        = string
  default     = "example-key"
}


# ==============================================================================
# VPC Configuration
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.240.0.0/24"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "vpc_zones" {
  description = "Number of availability zones to use (1-3)"
  type        = number
  default     = 2
  validation {
    condition     = var.vpc_zones >= 1 && var.vpc_zones <= 3
    error_message = "VPC zones must be between 1 and 3."
  }
}

variable "enable_public_gateway" {
  description = "Enable public gateway for VPC subnets"
  type        = bool
  default     = false
}

# ==============================================================================
# VPN Gateway Configuration
# ==============================================================================

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway in VPC"
  type        = bool
  default     = true
}

variable "vpn_mode" {
  description = "VPN Gateway mode (route or policy)"
  type        = string
  default     = "route"
  validation {
    condition     = contains(["route", "policy"], var.vpn_mode)
    error_message = "VPN mode must be either 'route' or 'policy'."
  }
}

# ==============================================================================
# VPE Configuration
# ==============================================================================

variable "enable_vpe" {
  description = "Enable Virtual Private Endpoint for COS"
  type        = bool
  default     = true
}

variable "cos_instance_crn" {
  description = "CRN of the Cloud Object Storage instance for VPE"
  type        = string
  default     = ""
}

# ==============================================================================
# Power VS Configuration
# ==============================================================================

variable "power_vs_zone" {
  description = "Power VS zone (e.g., us-south, dal12, lon04)"
  type        = string
  default     = "us-south"
}

variable "power_vs_network_cidr" {
  description = "CIDR block for Power VS private network"
  type        = string
  default     = "192.168.10.0/24"
  validation {
    condition     = can(cidrhost(var.power_vs_network_cidr, 0))
    error_message = "Power VS network CIDR must be a valid IPv4 CIDR block."
  }
}

variable "power_vs_instance_count" {
  description = "Number of Power VS instances to create"
  type        = number
  default     = 2
  validation {
    condition     = var.power_vs_instance_count >= 0 && var.power_vs_instance_count <= 10
    error_message = "Instance count must be between 0 and 10."
  }
}

variable "power_vs_image_name" {
  description = "Power VS image name (e.g., RHEL8-SP4, SLES15-SP3)"
  type        = string
  default     = "RHEL8-SP4"
}

variable "power_vs_processor_type" {
  description = "Processor type (shared or dedicated)"
  type        = string
  default     = "shared"
  validation {
    condition     = contains(["shared", "dedicated", "capped"], var.power_vs_processor_type)
    error_message = "Processor type must be 'shared', 'dedicated', or 'capped'."
  }
}

variable "power_vs_cores" {
  description = "Number of cores per Power VS instance"
  type        = number
  default     = 2
  validation {
    condition     = var.power_vs_cores >= 0.25 && var.power_vs_cores <= 32
    error_message = "Cores must be between 0.25 and 32."
  }
}

variable "power_vs_memory" {
  description = "Memory in GB per Power VS instance"
  type        = number
  default     = 16
  validation {
    condition     = var.power_vs_memory >= 2 && var.power_vs_memory <= 512
    error_message = "Memory must be between 2 and 512 GB."
  }
}

variable "power_vs_storage_size" {
  description = "Storage size in GB per Power VS instance"
  type        = number
  default     = 100
  validation {
    condition     = var.power_vs_storage_size >= 20 && var.power_vs_storage_size <= 2000
    error_message = "Storage size must be between 20 and 2000 GB."
  }
}

variable "power_vs_storage_type" {
  description = "Storage type (tier1 or tier3)"
  type        = string
  default     = "tier3"
  validation {
    condition     = contains(["tier1", "tier3"], var.power_vs_storage_type)
    error_message = "Storage type must be 'tier1' or 'tier3'."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for Power VS instance access"
  type        = string
  default     = ""
}

# ==============================================================================
# Transit Gateway Configuration
# ==============================================================================

variable "enable_transit_gateway" {
  description = "Enable Transit Gateway to connect VPC and Power VS"
  type        = bool
  default     = true
}

variable "transit_gateway_global" {
  description = "Enable global routing for Transit Gateway"
  type        = bool
  default     = false
}