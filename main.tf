# Data source to get existing resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# ==============================================================================
# VPC Resources
# ==============================================================================

# Create VPC
resource "ibm_is_vpc" "vpc" {
  name                      = var.project_name
  resource_group            = data.ibm_resource_group.resource_group.id
  address_prefix_management = "manual"
  tags                      = var.tags
}

# Create address prefix for the custom CIDR
resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  name = "${var.project_name}-prefix-1"
  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-1"
  cidr = "10.14.105.0/24"
}

# Create subnet in first availability zone
resource "ibm_is_subnet" "subnet" {
  name            = "${var.project_name}-subnet-1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.region}-1"
  ipv4_cidr_block = "10.14.105.0/24"
  resource_group  = data.ibm_resource_group.resource_group.id
  tags            = var.tags
  
  depends_on = [ibm_is_vpc_address_prefix.subnet_prefix]
}

# Create Public Gateway for internet connectivity
resource "ibm_is_public_gateway" "pgw" {
  name           = "${var.project_name}-pgw"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Attach Public Gateway to subnet
resource "ibm_is_subnet_public_gateway_attachment" "pgw_attachment" {
  subnet         = ibm_is_subnet.subnet.id
  public_gateway = ibm_is_public_gateway.pgw.id
}

# Create security group for VSI
resource "ibm_is_security_group" "vsi_sg" {
  name           = "${var.project_name}-vsi-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Allow SSH inbound
resource "ibm_is_security_group_rule" "vsi_sg_ssh" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# Allow ICMP (ping) inbound
resource "ibm_is_security_group_rule" "vsi_sg_icmp" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

# Allow all traffic from Power VS network
resource "ibm_is_security_group_rule" "vsi_sg_power_vs" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "inbound"
  remote    = "192.168.1.0/24"
}

# Allow all outbound traffic
resource "ibm_is_security_group_rule" "vsi_sg_outbound" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Use existing SSH key for VPC or create new one
data "ibm_is_ssh_key" "vpc_ssh_key" {
  name = "murali-key-n1-rsa"
}

# Secondary SSH key for additional access
data "ibm_is_ssh_key" "secondary_ssh_key" {
  name = "secondary-access-key"
}

# Get Ubuntu image
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

# Create Ubuntu VSI
resource "ibm_is_instance" "ubuntu_vsi" {
  name           = "${var.project_name}-ubuntu-vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu.id
  keys           = [data.ibm_is_ssh_key.vpc_ssh_key.id, data.ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
  }

  user_data = <<-EOF
    #!/bin/bash
    
    # Deploy SSH key for accessing Power VS LPARs
    mkdir -p /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    
    cat > /home/ubuntu/.ssh/murali-key-n1-rsa.prv <<'SSHKEY'
${file("${path.module}/murali-key-n1-rsa.prv")}
SSHKEY
    
    chmod 600 /home/ubuntu/.ssh/murali-key-n1-rsa.prv
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    
    # Configure routes and ARP entries for Power VS systems via NAT gateway
    cat > /etc/systemd/system/power-vs-routes.service <<'ROUTES_EOF'
    [Unit]
    Description=Routes and ARP entries for Power VS via NAT Gateway
    After=network.target

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/local/bin/setup-power-vs-routes.sh

    [Install]
    WantedBy=multi-user.target
    ROUTES_EOF

    cat > /usr/local/bin/setup-power-vs-routes.sh <<'SCRIPT_EOF'
    #!/bin/bash
    # Get NAT gateway MAC address (will be available after NAT gateway boots)
    NAT_GW_IP="10.14.105.254"
    
    # Wait for NAT gateway to be reachable
    for i in {1..30}; do
      if ping -c 1 -W 1 $NAT_GW_IP >/dev/null 2>&1; then
        break
      fi
      sleep 2
    done
    
    # Get NAT gateway MAC address
    NAT_GW_MAC=$(ip neigh show $NAT_GW_IP | awk '{print $5}')
    
    if [ -n "$NAT_GW_MAC" ]; then
      # Add static routes to Power VS NAT IPs via NAT gateway
      ip route add 10.14.105.5 via 10.14.105.254 2>/dev/null || true
      ip route add 10.14.105.7 via 10.14.105.254 2>/dev/null || true
      ip route add 10.14.105.9 via 10.14.105.254 2>/dev/null || true
      
      # Add static ARP entries for NAT IPs pointing to NAT gateway MAC
      ip neigh add 10.14.105.5 lladdr $NAT_GW_MAC dev $(ip route | grep default | awk '{print $5}') nud permanent 2>/dev/null || true
      ip neigh add 10.14.105.7 lladdr $NAT_GW_MAC dev $(ip route | grep default | awk '{print $5}') nud permanent 2>/dev/null || true
      ip neigh add 10.14.105.9 lladdr $NAT_GW_MAC dev $(ip route | grep default | awk '{print $5}') nud permanent 2>/dev/null || true
    fi
    SCRIPT_EOF

    chmod +x /usr/local/bin/setup-power-vs-routes.sh
    systemctl enable power-vs-routes.service
    systemctl start power-vs-routes.service
  EOF
}

# Create floating IP for VSI
resource "ibm_is_floating_ip" "vsi_fip" {
  name           = "${var.project_name}-vsi-fip"
  target         = ibm_is_instance.ubuntu_vsi.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# ==============================================================================
# Power VS Resources
# ==============================================================================

# Create Power VS workspace
resource "ibm_resource_instance" "power_vs_workspace" {
  name              = "mmn-pvs-vpc-nat-ws"
  service           = "power-iaas"
  plan              = "power-virtual-server-group"
  location          = "wdc06"
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Create Power VS SSH key (Power VS requires RSA keys)
resource "ibm_pi_key" "power_vs_ssh_key" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_key_name          = "murali-key-n1-rsa"
  pi_ssh_key           = file("${path.module}/murai-key-n1-rsa.pub")
}

# Create secondary Power VS SSH key
resource "ibm_pi_key" "power_vs_secondary_ssh_key" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_key_name          = "secondary-access-key"
  pi_ssh_key           = file("${path.module}/ssh-keys/secondary-key-rsa.pub")
}

# Create Power VS private network
resource "ibm_pi_network" "power_vs_network" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_network_name      = "${var.project_name}-power-network"
  pi_network_type      = "vlan"
  pi_cidr              = "192.168.1.0/24"
  pi_dns               = ["9.9.9.9"]
}

# Fetch available catalog images for Power VS workspace
data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
}

# Find CentOS image from catalog
locals {
  # Filter for CentOS images (case-insensitive search for "centos")
  centos_images = [for image in data.ibm_pi_catalog_images.catalog_images.images :
    image if can(regex("(?i)centos", image.name))
  ]
  
  # Use the first CentOS image found, or fail if none available
  centos_image_id = length(local.centos_images) > 0 ? local.centos_images[0].image_id : null
  centos_image_name = length(local.centos_images) > 0 ? local.centos_images[0].name : "No CentOS image found"
}

# Power VS Network Routes for unified subnet addressing
# These routes enable LPAR-to-LPAR communication via 10.14.105.x addresses
resource "ibm_pi_route" "centos_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-centos-lpar"
  pi_destination       = "10.14.105.5"
  pi_next_hop          = "192.168.1.5"
  pi_enabled           = true
  
  depends_on = [
    ibm_pi_network.power_vs_network,
    ibm_pi_instance.centos_lpar
  ]
}

resource "ibm_pi_route" "rhel9_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-rhel9-lpar"
  pi_destination       = "10.14.105.7"
  pi_next_hop          = "192.168.1.7"
  pi_enabled           = true
  
  depends_on = [
    ibm_pi_network.power_vs_network,
    ibm_pi_instance.rhel9_lpar
  ]
}

resource "ibm_pi_route" "rhel8_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-rhel8-lpar"
  pi_destination       = "10.14.105.9"
  pi_next_hop          = "192.168.1.9"
  pi_enabled           = true
  
  depends_on = [
    ibm_pi_network.power_vs_network,
    ibm_pi_instance.rhel8_lpar
  ]
}


# Create Power VS CentOS LPAR
resource "ibm_pi_instance" "centos_lpar" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.project_name}-centos-lpar"
  pi_image_id          = local.centos_image_id  # Dynamically selected from catalog
  pi_key_pair_name     = ibm_pi_key.power_vs_ssh_key.name
  pi_sys_type          = "s922"
  pi_proc_type         = "shared"
  pi_processors        = 0.25
  pi_memory            = 2
  pi_storage_type      = "tier3"

  pi_network {
    network_id = ibm_pi_network.power_vs_network.network_id
    ip_address = "192.168.1.5"  # Manually assign IP matching last octet
  }
  
  depends_on = [
    ibm_pi_key.power_vs_ssh_key,
    ibm_pi_network.power_vs_network
  ]

  # Configure secondary IP for unified subnet (10.14.105.5)
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "sleep 60",
      "echo 'Configuring secondary IP 10.14.105.5/32 on env2 interface...'",
      "ip addr add 10.14.105.5/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses 10.14.105.5/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.5|10.14.105.5'"
    ]
    
    connection {
      type                = "ssh"
      host                = self.pi_network[0].ip_address
      user                = "root"
      private_key         = file("${path.module}/murali-key-n1-rsa.prv")
      timeout             = "15m"
      
      # Use VPC VSI as bastion/jump host to reach private Power VS network
      bastion_host        = ibm_is_floating_ip.vsi_fip.address
      bastion_user        = "ubuntu"
      bastion_private_key = file("${path.module}/murali-key-n1-rsa.prv")
    }
  }
}

# ==============================================================================
# Transit Gateway
# ==============================================================================

# Create Transit Gateway
resource "ibm_tg_gateway" "transit_gateway" {
  name           = "${var.project_name}-tgw"
  location       = var.region
  global         = false
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Connect VPC to Transit Gateway
resource "ibm_tg_connection" "vpc_connection" {
  gateway      = ibm_tg_gateway.transit_gateway.id
  network_type = "vpc"
  name         = "${var.project_name}-vpc-connection"
  network_id   = ibm_is_vpc.vpc.crn
}

# Connect Power VS to Transit Gateway
resource "ibm_tg_connection" "power_vs_connection" {
  gateway      = ibm_tg_gateway.transit_gateway.id
  network_type = "power_virtual_server"
  name         = "${var.project_name}-power-vs-connection"
  network_id   = ibm_resource_instance.power_vs_workspace.crn
}