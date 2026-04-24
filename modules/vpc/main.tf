# ==============================================================================
# VPC Resource
# ==============================================================================

resource "ibm_is_vpc" "vpc" {
  name                        = "${var.name_prefix}-vpc"
  resource_group              = var.resource_group_id
  classic_access              = false
  address_prefix_management   = "manual"
  default_network_acl_name    = "${var.name_prefix}-default-acl"
  default_security_group_name = "${var.name_prefix}-default-sg"
  default_routing_table_name  = "${var.name_prefix}-default-rt"
  tags                        = var.tags
}

# ==============================================================================
# Address Prefixes
# ==============================================================================

resource "ibm_is_vpc_address_prefix" "prefix" {
  count = length(var.zones)

  name = "${var.name_prefix}-prefix-${count.index + 1}"
  vpc  = ibm_is_vpc.vpc.id
  zone = var.zones[count.index]
  cidr = var.subnet_cidrs[count.index]
}

# ==============================================================================
# Public Gateways (Optional)
# ==============================================================================

resource "ibm_is_public_gateway" "pgw" {
  count = var.enable_public_gateway ? length(var.zones) : 0

  name           = "${var.name_prefix}-pgw-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zones[count.index]
  resource_group = var.resource_group_id
  tags           = var.tags
}

# ==============================================================================
# Subnets
# ==============================================================================

resource "ibm_is_subnet" "subnet" {
  count = length(var.zones)

  name                     = "${var.name_prefix}-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zones[count.index]
  ipv4_cidr_block          = var.subnet_cidrs[count.index]
  resource_group           = var.resource_group_id
  public_gateway           = var.enable_public_gateway ? ibm_is_public_gateway.pgw[count.index].id : null
  tags                     = var.tags

  depends_on = [ibm_is_vpc_address_prefix.prefix]
}

# ==============================================================================
# Security Group
# ==============================================================================

resource "ibm_is_security_group" "sg" {
  name           = "${var.name_prefix}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Security Group Rules - Inbound

# Allow SSH from anywhere (adjust for production)
resource "ibm_is_security_group_rule" "inbound_ssh" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

# Allow ICMP (ping) from anywhere
resource "ibm_is_security_group_rule" "inbound_icmp" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

# Allow all traffic from VPC CIDR
resource "ibm_is_security_group_rule" "inbound_vpc" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.vpc_cidr
}

# Allow all traffic from Power VS network
resource "ibm_is_security_group_rule" "inbound_power_vs" {
  count = var.power_vs_cidr != "" ? 1 : 0

  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.power_vs_cidr
}

# Security Group Rules - Outbound

# Allow all outbound traffic
resource "ibm_is_security_group_rule" "outbound_all" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# ==============================================================================
# Network ACL
# ==============================================================================

resource "ibm_is_network_acl" "acl" {
  name           = "${var.name_prefix}-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  tags           = var.tags

  # Inbound Rules
  rules {
    name        = "inbound-ssh"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min        = 22
      port_max        = 22
      source_port_min = 1024
      source_port_max = 65535
    }
  }

  rules {
    name        = "inbound-icmp"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    icmp {
      type = 8
    }
  }

  rules {
    name        = "inbound-vpc"
    action      = "allow"
    source      = var.vpc_cidr
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }

  # Outbound Rules
  rules {
    name        = "outbound-all"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
}

# Apply ACL to subnets
resource "ibm_is_subnet_network_acl_attachment" "acl_attachment" {
  count = length(var.zones)

  subnet      = ibm_is_subnet.subnet[count.index].id
  network_acl = ibm_is_network_acl.acl.id
}