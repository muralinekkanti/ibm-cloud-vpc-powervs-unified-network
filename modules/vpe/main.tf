# ==============================================================================
# Virtual Private Endpoint Gateway for Cloud Object Storage
# ==============================================================================

resource "ibm_is_virtual_endpoint_gateway" "vpe" {
  name           = "${var.name_prefix}-vpe-cos"
  vpc            = var.vpc_id
  resource_group = var.resource_group_id
  tags           = var.tags

  target {
    crn           = var.cos_instance_crn
    resource_type = "provider_cloud_service"
  }

  # Create reserved IPs in each subnet
  dynamic "ips" {
    for_each = var.subnet_ids
    content {
      subnet = ips.value
      name   = "${var.name_prefix}-vpe-ip-${ips.key + 1}"
    }
  }
}

# ==============================================================================
# Security Group for VPE (Optional)
# ==============================================================================

resource "ibm_is_security_group" "vpe_sg" {
  name           = "${var.name_prefix}-vpe-sg"
  vpc            = var.vpc_id
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Allow HTTPS traffic to COS
resource "ibm_is_security_group_rule" "vpe_inbound_https" {
  group     = ibm_is_security_group.vpe_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

# Allow all outbound traffic
resource "ibm_is_security_group_rule" "vpe_outbound_all" {
  group     = ibm_is_security_group.vpe_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Attach security group to VPE
resource "ibm_is_virtual_endpoint_gateway_ip" "vpe_sg_attachment" {
  count = length(var.subnet_ids)

  gateway     = ibm_is_virtual_endpoint_gateway.vpe.id
  reserved_ip = ibm_is_virtual_endpoint_gateway.vpe.ips[count.index].id
}