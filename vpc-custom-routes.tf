# VPC Custom Routes for NAT Gateway
# These routes direct traffic to Power VS NAT IPs through the NAT Gateway

# Note: Transit Gateway automatically handles routing for 192.168.1.0/24
# No explicit VPC route needed for the Power VS network itself

resource "ibm_is_vpc_routing_table_route" "nat_route_centos" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "us-east-1"
  name          = "nat-route-centos"
  destination   = "10.14.105.5/32"
  action        = "deliver"
  next_hop      = ibm_is_instance.nat_gateway.primary_network_interface[0].primary_ip[0].address
}

resource "ibm_is_vpc_routing_table_route" "nat_route_rhel9" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "us-east-1"
  name          = "nat-route-rhel9"
  destination   = "10.14.105.7/32"
  action        = "deliver"
  next_hop      = ibm_is_instance.nat_gateway.primary_network_interface[0].primary_ip[0].address
}

resource "ibm_is_vpc_routing_table_route" "nat_route_rhel8" {
  vpc           = ibm_is_vpc.vpc.id
  routing_table = ibm_is_vpc.vpc.default_routing_table
  zone          = "us-east-1"
  name          = "nat-route-rhel8"
  destination   = "10.14.105.9/32"
  action        = "deliver"
  next_hop      = ibm_is_instance.nat_gateway.primary_network_interface[0].primary_ip[0].address
}