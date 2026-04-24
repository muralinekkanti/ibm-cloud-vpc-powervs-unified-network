variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for VPN Gateway"
  type        = string
}

variable "mode" {
  description = "VPN Gateway mode (route or policy)"
  type        = string
  default     = "route"
  validation {
    condition     = contains(["route", "policy"], var.mode)
    error_message = "Mode must be either 'route' or 'policy'."
  }
}

variable "tags" {
  description = "List of tags"
  type        = list(string)
  default     = []
}

# ==============================================================================
# VPN Connection Configuration
# ==============================================================================

variable "enable_vpn_connection" {
  description = "Enable VPN connection creation"
  type        = bool
  default     = false
}

variable "peer_gateway_ip" {
  description = "IP address of the peer VPN gateway"
  type        = string
  default     = ""
}

variable "preshared_key" {
  description = "Pre-shared key for VPN connection"
  type        = string
  sensitive   = true
  default     = ""
}

variable "local_cidrs" {
  description = "Local CIDR blocks for VPN connection (used when BGP is disabled)"
  type        = list(string)
  default     = []
}

variable "peer_cidrs" {
  description = "Peer CIDR blocks for VPN connection (used when BGP is disabled)"
  type        = list(string)
  default     = []
}

# ==============================================================================
# BGP Configuration
# ==============================================================================

variable "enable_bgp" {
  description = "Enable BGP for dynamic routing (only for route-based VPN)"
  type        = bool
  default     = false
}

variable "bgp_asn" {
  description = "BGP ASN for the VPN gateway (IBM Cloud side)"
  type        = number
  default     = 64512
  validation {
    condition     = var.bgp_asn >= 1 && var.bgp_asn <= 4294967295
    error_message = "BGP ASN must be between 1 and 4294967295."
  }
}

variable "peer_bgp_asn" {
  description = "BGP ASN for the peer gateway"
  type        = number
  default     = 64513
  validation {
    condition     = var.peer_bgp_asn >= 1 && var.peer_bgp_asn <= 4294967295
    error_message = "Peer BGP ASN must be between 1 and 4294967295."
  }
}

# ==============================================================================
# IKE Policy Configuration
# ==============================================================================

variable "ike_version" {
  description = "IKE protocol version (1 or 2)"
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.ike_version)
    error_message = "IKE version must be 1 or 2."
  }
}

variable "ike_authentication_algorithm" {
  description = "IKE authentication algorithm"
  type        = string
  default     = "sha256"
  validation {
    condition     = contains(["sha256", "sha384", "sha512"], var.ike_authentication_algorithm)
    error_message = "IKE authentication algorithm must be sha256, sha384, or sha512."
  }
}

variable "ike_encryption_algorithm" {
  description = "IKE encryption algorithm"
  type        = string
  default     = "aes256"
  validation {
    condition     = contains(["aes128", "aes192", "aes256"], var.ike_encryption_algorithm)
    error_message = "IKE encryption algorithm must be aes128, aes192, or aes256."
  }
}

variable "ike_dh_group" {
  description = "IKE Diffie-Hellman group"
  type        = number
  default     = 14
  validation {
    condition     = contains([2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24], var.ike_dh_group)
    error_message = "IKE DH group must be a valid group number."
  }
}

# ==============================================================================
# IPsec Policy Configuration
# ==============================================================================

variable "ipsec_authentication_algorithm" {
  description = "IPsec authentication algorithm"
  type        = string
  default     = "sha256"
  validation {
    condition     = contains(["sha256", "sha384", "sha512"], var.ipsec_authentication_algorithm)
    error_message = "IPsec authentication algorithm must be sha256, sha384, or sha512."
  }
}

variable "ipsec_encryption_algorithm" {
  description = "IPsec encryption algorithm"
  type        = string
  default     = "aes256"
  validation {
    condition     = contains(["aes128", "aes192", "aes256"], var.ipsec_encryption_algorithm)
    error_message = "IPsec encryption algorithm must be aes128, aes192, or aes256."
  }
}

variable "ipsec_pfs" {
  description = "IPsec Perfect Forward Secrecy group"
  type        = string
  default     = "group_14"
  validation {
    condition     = contains(["disabled", "group_2", "group_5", "group_14", "group_15", "group_16", "group_17", "group_18", "group_19", "group_20", "group_21", "group_22", "group_23", "group_24"], var.ipsec_pfs)
    error_message = "IPsec PFS must be a valid group or 'disabled'."
  }
}

# ==============================================================================
# Dead Peer Detection (DPD) Configuration
# ==============================================================================

variable "dpd_action" {
  description = "Dead Peer Detection action (restart, clear, hold, none)"
  type        = string
  default     = "restart"
  validation {
    condition     = contains(["restart", "clear", "hold", "none"], var.dpd_action)
    error_message = "DPD action must be restart, clear, hold, or none."
  }
}

variable "dpd_interval" {
  description = "Dead Peer Detection interval in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.dpd_interval >= 15 && var.dpd_interval <= 86400
    error_message = "DPD interval must be between 15 and 86400 seconds."
  }
}

variable "dpd_timeout" {
  description = "Dead Peer Detection timeout in seconds"
  type        = number
  default     = 120
  validation {
    condition     = var.dpd_timeout >= 30 && var.dpd_timeout <= 86400
    error_message = "DPD timeout must be between 30 and 86400 seconds."
  }
}

# ==============================================================================
# VPN Server Configuration (Optional)
# ==============================================================================

variable "enable_vpn_server" {
  description = "Enable VPN Server for client-to-site VPN"
  type        = bool
  default     = false
}

variable "vpn_server_certificate_crn" {
  description = "CRN of the certificate for VPN Server"
  type        = string
  default     = ""
}

variable "vpn_server_client_ca_crn" {
  description = "CRN of the client CA certificate for VPN Server"
  type        = string
  default     = ""
}

variable "vpn_server_client_ip_pool" {
  description = "IP pool for VPN Server clients"
  type        = string
  default     = "10.250.0.0/20"
}

variable "vpn_server_enable_split_tunneling" {
  description = "Enable split tunneling for VPN Server"
  type        = bool
  default     = false
}