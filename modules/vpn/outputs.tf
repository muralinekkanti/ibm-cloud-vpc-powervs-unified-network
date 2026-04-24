output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.id
}

output "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.name
}

output "vpn_gateway_public_ip" {
  description = "Public IP address of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.public_ip_address
}

output "vpn_gateway_public_ip_address2" {
  description = "Second public IP address of the VPN Gateway (HA)"
  value       = ibm_is_vpn_gateway.vpn.public_ip_address2
}

output "vpn_gateway_status" {
  description = "Status of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.status
}

output "vpn_gateway_mode" {
  description = "Mode of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.mode
}

output "vpn_gateway_crn" {
  description = "CRN of the VPN Gateway"
  value       = ibm_is_vpn_gateway.vpn.crn
}

# ==============================================================================
# VPN Connection Outputs
# ==============================================================================

output "vpn_connection_id" {
  description = "ID of the VPN connection"
  value       = var.enable_vpn_connection ? (var.enable_bgp && var.mode == "route" ? ibm_is_vpn_gateway_connection.bgp_connection[0].id : ibm_is_vpn_gateway_connection.connection[0].id) : null
}

output "vpn_connection_status" {
  description = "Status of the VPN connection"
  value       = var.enable_vpn_connection ? (var.enable_bgp && var.mode == "route" ? ibm_is_vpn_gateway_connection.bgp_connection[0].status : ibm_is_vpn_gateway_connection.connection[0].status) : null
}

output "vpn_connection_name" {
  description = "Name of the VPN connection"
  value       = var.enable_vpn_connection ? (var.enable_bgp && var.mode == "route" ? ibm_is_vpn_gateway_connection.bgp_connection[0].name : ibm_is_vpn_gateway_connection.connection[0].name) : null
}

# ==============================================================================
# BGP Outputs
# ==============================================================================

output "bgp_enabled" {
  description = "Whether BGP is enabled for the VPN connection"
  value       = var.enable_bgp && var.mode == "route"
}

output "bgp_asn" {
  description = "BGP ASN for the VPN gateway (IBM Cloud side)"
  value       = var.enable_bgp ? var.bgp_asn : null
}

output "peer_bgp_asn" {
  description = "BGP ASN for the peer gateway"
  value       = var.enable_bgp ? var.peer_bgp_asn : null
}

# ==============================================================================
# Connection Details
# ==============================================================================

output "connection_details" {
  description = "Detailed information about the VPN connection"
  value = var.enable_vpn_connection ? {
    connection_id   = var.enable_bgp && var.mode == "route" ? ibm_is_vpn_gateway_connection.bgp_connection[0].id : ibm_is_vpn_gateway_connection.connection[0].id
    peer_address    = var.peer_gateway_ip
    mode            = var.mode
    bgp_enabled     = var.enable_bgp && var.mode == "route"
    ike_version     = var.ike_version
    dpd_action      = var.dpd_action
    dpd_interval    = var.dpd_interval
    dpd_timeout     = var.dpd_timeout
  } : null
  sensitive = false
}