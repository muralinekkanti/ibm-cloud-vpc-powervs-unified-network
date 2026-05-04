# VPC Custom Routes for Power VS LPAR Access
# Routes traffic for odd-numbered 10.14.105.x IPs to their corresponding Power VS LPAR IPs
# Transit Gateway handles the actual packet forwarding between VPC and Power VS networks

resource "ibm_is_vpc_routing_table_route" "centos_lpar_route" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "${var.region}-1"
  name          = "route-to-centos-lpar"
  destination   = "${local.centos_lpar_ip}/32"  # 10.14.105.5/32
  action        = "deliver"
  next_hop      = ibm_pi_instance.centos_lpar.pi_network[0].ip_address  # CentOS LPAR actual IP in Power VS network
  
  depends_on = [
    ibm_is_subnet.subnet,
    ibm_tg_connection.vpc_connection,
    ibm_pi_instance.centos_lpar
  ]
}

resource "ibm_is_vpc_routing_table_route" "rhel9_lpar_route" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "${var.region}-1"
  name          = "route-to-rhel9-lpar"
  destination   = "${local.rhel9_lpar_ip}/32"  # 10.14.105.7/32
  action        = "deliver"
  next_hop      = ibm_pi_instance.rhel9_lpar.pi_network[0].ip_address  # RHEL 9 LPAR actual IP in Power VS network
  
  depends_on = [
    ibm_is_subnet.subnet,
    ibm_tg_connection.vpc_connection,
    ibm_pi_instance.rhel9_lpar
  ]
}

resource "ibm_is_vpc_routing_table_route" "rhel8_lpar_route" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "${var.region}-1"
  name          = "route-to-rhel8-lpar"
  destination   = "${local.rhel8_lpar_ip}/32"  # 10.14.105.9/32
  action        = "deliver"
  next_hop      = ibm_pi_instance.rhel8_lpar.pi_network[0].ip_address  # RHEL 8 LPAR actual IP in Power VS network
  
  depends_on = [
    ibm_is_subnet.subnet,
    ibm_tg_connection.vpc_connection,
    ibm_pi_instance.rhel8_lpar
  ]
}