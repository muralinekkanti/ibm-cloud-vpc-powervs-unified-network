# ==============================================================================
# Transit Gateway
# ==============================================================================

resource "ibm_tg_gateway" "transit_gateway" {
  name           = "${var.name_prefix}-tgw"
  location       = var.location
  global         = var.global_routing
  resource_group = var.resource_group_id
  tags           = var.tags

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# ==============================================================================
# VPC Connection
# ==============================================================================

resource "ibm_tg_connection" "vpc_connection" {
  gateway      = ibm_tg_gateway.transit_gateway.id
  network_type = "vpc"
  name         = "${var.name_prefix}-vpc-connection"
  network_id   = var.vpc_crn

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# ==============================================================================
# Power VS Connection
# ==============================================================================

resource "ibm_tg_connection" "power_vs_connection" {
  gateway      = ibm_tg_gateway.transit_gateway.id
  network_type = "power_virtual_server"
  name         = "${var.name_prefix}-power-connection"
  network_id   = var.power_vs_crn

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# ==============================================================================
# Wait for connections to be attached
# ==============================================================================

resource "time_sleep" "wait_for_connections" {
  depends_on = [
    ibm_tg_connection.vpc_connection,
    ibm_tg_connection.power_vs_connection
  ]

  create_duration = "60s"
}