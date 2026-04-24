# ==============================================================================
# VPN Gateway with BGP Support
# ==============================================================================

resource "ibm_is_vpn_gateway" "vpn" {
  name           = "${var.name_prefix}-vpn-gateway"
  subnet         = var.subnet_id
  mode           = var.mode
  resource_group = var.resource_group_id
  tags           = var.tags
}

# ==============================================================================
# VPN Gateway Connection with BGP
# ==============================================================================

# Create VPN connection when peer details are provided
resource "ibm_is_vpn_gateway_connection" "connection" {
  count = var.enable_vpn_connection ? 1 : 0

  name           = "${var.name_prefix}-vpn-connection"
  vpn_gateway    = ibm_is_vpn_gateway.vpn.id
  peer_address   = var.peer_gateway_ip
  preshared_key  = var.preshared_key
  admin_state_up = true

  # Static routing (when BGP is disabled)
  local_cidrs = var.enable_bgp ? [] : var.local_cidrs
  peer_cidrs  = var.enable_bgp ? [] : var.peer_cidrs

  # IKE Policy Configuration
  ike_policy {
    authentication_algorithm = var.ike_authentication_algorithm
    encryption_algorithm     = var.ike_encryption_algorithm
    dh_group                 = var.ike_dh_group
    ike_version              = var.ike_version
  }

  # IPsec Policy Configuration
  ipsec_policy {
    authentication_algorithm = var.ipsec_authentication_algorithm
    encryption_algorithm     = var.ipsec_encryption_algorithm
    pfs                      = var.ipsec_pfs
  }

  # Dead Peer Detection
  action      = var.dpd_action
  interval    = var.dpd_interval
  timeout     = var.dpd_timeout

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# ==============================================================================
# BGP Configuration for Route-Based VPN
# ==============================================================================

# Configure BGP on the VPN connection
resource "ibm_is_vpn_gateway_connection" "bgp_connection" {
  count = var.enable_vpn_connection && var.enable_bgp && var.mode == "route" ? 1 : 0

  name           = "${var.name_prefix}-vpn-bgp-connection"
  vpn_gateway    = ibm_is_vpn_gateway.vpn.id
  peer_address   = var.peer_gateway_ip
  preshared_key  = var.preshared_key
  admin_state_up = true

  # BGP Configuration
  local_cidrs = []
  peer_cidrs  = []

  # IKE Policy
  ike_policy {
    authentication_algorithm = var.ike_authentication_algorithm
    encryption_algorithm     = var.ike_encryption_algorithm
    dh_group                 = var.ike_dh_group
    ike_version              = var.ike_version
  }

  # IPsec Policy
  ipsec_policy {
    authentication_algorithm = var.ipsec_authentication_algorithm
    encryption_algorithm     = var.ipsec_encryption_algorithm
    pfs                      = var.ipsec_pfs
  }

  # Dead Peer Detection
  action      = var.dpd_action
  interval    = var.dpd_interval
  timeout     = var.dpd_timeout

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# ==============================================================================
# VPN Server (Optional - for Client-to-Site VPN)
# ==============================================================================

# Uncomment to enable VPN Server for client connections
# resource "ibm_is_vpn_server" "vpn_server" {
#   count = var.enable_vpn_server ? 1 : 0
#
#   name                 = "${var.name_prefix}-vpn-server"
#   certificate_crn      = var.vpn_server_certificate_crn
#   client_authentication {
#     method            = "certificate"
#     client_ca_crn     = var.vpn_server_client_ca_crn
#   }
#   client_ip_pool       = var.vpn_server_client_ip_pool
#   subnets              = [var.subnet_id]
#   resource_group       = var.resource_group_id
#   enable_split_tunneling = var.vpn_server_enable_split_tunneling
#
#   tags = var.tags
# }