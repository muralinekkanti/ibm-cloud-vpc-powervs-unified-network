# ==============================================================================
# Unified Subnet Test Environment
# This file adds resources to simulate on-prem environment with mixed x86 and Power
# ==============================================================================

# ==============================================================================
# Additional VPC VSIs
# ==============================================================================

# Second Ubuntu VSI (10.14.105.6)
resource "ibm_is_instance" "ubuntu_vsi_2" {
  name           = "${var.project_name}-ubuntu-vsi-2"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu.id
  keys           = [data.ibm_is_ssh_key.vpc_ssh_key.id, data.ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = concat(var.tags, ["x86", "ubuntu"])

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
    primary_ip {
      address = "10.14.105.6"
      name    = "${var.project_name}-ubuntu-vsi-2-ip"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
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
      IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
      ip neigh add 10.14.105.5 lladdr $NAT_GW_MAC dev $IFACE nud permanent 2>/dev/null || true
      ip neigh add 10.14.105.7 lladdr $NAT_GW_MAC dev $IFACE nud permanent 2>/dev/null || true
      ip neigh add 10.14.105.9 lladdr $NAT_GW_MAC dev $IFACE nud permanent 2>/dev/null || true
    fi
    SCRIPT_EOF

    chmod +x /usr/local/bin/setup-power-vs-routes.sh
    systemctl enable power-vs-routes.service
    systemctl start power-vs-routes.service
  EOF
}

# Get Windows Server image
data "ibm_is_image" "windows" {
  name = "ibm-windows-server-2022-full-standard-amd64-12"
}

# Windows VSI (10.14.105.8)
resource "ibm_is_instance" "windows_vsi" {
  name           = "${var.project_name}-windows-vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "bx2-2x8"  # Windows needs more RAM
  image          = data.ibm_is_image.windows.id
  keys           = [data.ibm_is_ssh_key.vpc_ssh_key.id, data.ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = concat(var.tags, ["x86", "windows"])

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id, ibm_is_security_group.windows_sg.id]
    primary_ip {
      address = "10.14.105.8"
      name    = "${var.project_name}-windows-vsi-ip"
    }
  }

  user_data = <<-EOF
    <powershell>
    # Configure routes to Power VS systems via NAT gateway
    route add 10.14.105.5 mask 255.255.255.255 10.14.105.254 -p
    route add 10.14.105.7 mask 255.255.255.255 10.14.105.254 -p
    route add 10.14.105.9 mask 255.255.255.255 10.14.105.254 -p
    </powershell>
  EOF
}

# Security group for Windows (RDP access)
resource "ibm_is_security_group" "windows_sg" {
  name           = "${var.project_name}-windows-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Allow RDP inbound
resource "ibm_is_security_group_rule" "windows_sg_rdp" {
  group     = ibm_is_security_group.windows_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 3389
    port_max = 3389
  }
}

# Floating IP for Windows VSI
resource "ibm_is_floating_ip" "windows_fip" {
  name           = "${var.project_name}-windows-fip"
  target         = ibm_is_instance.windows_vsi.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# ==============================================================================
# NAT Gateway VSI
# ==============================================================================

resource "ibm_is_instance" "nat_gateway" {
  name           = "${var.project_name}-nat-gateway"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu.id
  keys           = [data.ibm_is_ssh_key.vpc_ssh_key.id, data.ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = concat(var.tags, ["nat-gateway"])

  primary_network_interface {
    subnet            = ibm_is_subnet.subnet.id
    security_groups   = [ibm_is_security_group.nat_sg.id]
    allow_ip_spoofing = true
    primary_ip {
      address = "10.14.105.254"
      name    = "${var.project_name}-nat-gateway-ip"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/nat-gateway-init.log)
    exec 2>&1

    echo "Starting NAT Gateway initialization..."

    # Update and install required packages
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent conntrack

    # Get network interface
    IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    echo "Network interface: $IFACE"

    # Configure system settings for NAT
    cat >> /etc/sysctl.conf <<'SYSCTL_EOF'
    # Enable IP forwarding
    net.ipv4.ip_forward=1

    # Enable proxy ARP (required for NAT gateway)
    net.ipv4.conf.all.proxy_arp=1
    net.ipv4.conf.default.proxy_arp=1

    # Disable reverse path filtering (required for NAT)
    net.ipv4.conf.all.rp_filter=0
    net.ipv4.conf.default.rp_filter=0
    SYSCTL_EOF

    # Apply sysctl settings
    sysctl -p

    # Enable proxy ARP on interface (use variable substitution properly)
    sysctl -w "net.ipv4.conf.$${IFACE}.proxy_arp=1"
    sysctl -w "net.ipv4.conf.$${IFACE}.rp_filter=0"

    # Add secondary IPs for Power VS mappings (matching last octet)
    ip addr add 10.14.105.5/24 dev $IFACE || true
    ip addr add 10.14.105.7/24 dev $IFACE || true
    ip addr add 10.14.105.9/24 dev $IFACE || true

    # Add route to Power VS network via Transit Gateway
    ip route add 192.168.1.0/24 via 10.14.105.1 dev $IFACE || true

    # Configure NAT rules
    # DNAT: Translate destination from VPC NAT IPs to Power VS IPs
    iptables -t nat -A PREROUTING -d 10.14.105.5 -j DNAT --to-destination 192.168.1.5
    iptables -t nat -A PREROUTING -d 10.14.105.7 -j DNAT --to-destination 192.168.1.7
    iptables -t nat -A PREROUTING -d 10.14.105.9 -j DNAT --to-destination 192.168.1.9

    # MASQUERADE: Use primary IP for source translation (critical for Transit Gateway routing)
    # This ensures replies can route back through Transit Gateway
    iptables -t nat -A POSTROUTING -d 192.168.1.0/24 -j MASQUERADE

    # FORWARD rules: Allow packet forwarding through NAT gateway
    iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
    iptables -A FORWARD -d 192.168.1.0/24 -j ACCEPT

    # Save iptables rules
    netfilter-persistent save

    # Create systemd service for persistence
    cat > /etc/systemd/system/nat-gateway.service <<'SERVICE_EOF'
    [Unit]
    Description=NAT Gateway Configuration
    After=network.target

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/local/bin/nat-gateway-setup.sh

    [Install]
    WantedBy=multi-user.target
    SERVICE_EOF

    # Create setup script for reboot persistence
    cat > /usr/local/bin/nat-gateway-setup.sh <<'SETUP_EOF'
    #!/bin/bash
    IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    
    # System settings
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv4.conf.all.proxy_arp=1
    sysctl -w net.ipv4.conf.$IFACE.proxy_arp=1
    sysctl -w net.ipv4.conf.all.rp_filter=0
    sysctl -w net.ipv4.conf.$IFACE.rp_filter=0
    
    # Secondary IPs
    ip addr add 10.14.105.5/24 dev $IFACE 2>/dev/null || true
    ip addr add 10.14.105.7/24 dev $IFACE 2>/dev/null || true
    ip addr add 10.14.105.9/24 dev $IFACE 2>/dev/null || true
    
    # Route to Power VS
    ip route add 192.168.1.0/24 via 10.14.105.1 dev $IFACE 2>/dev/null || true
    SETUP_EOF

    chmod +x /usr/local/bin/nat-gateway-setup.sh
    systemctl enable nat-gateway.service

    echo "NAT Gateway initialization complete!"
    echo "Configuration:"
    echo "  - IP forwarding: enabled"
    echo "  - Proxy ARP: enabled"
    echo "  - Reverse path filtering: disabled"
    echo "  - Secondary IPs: 10.14.105.5, .7, .9"
    echo "  - Route to Power VS: 192.168.1.0/24 via 10.14.105.1"
    echo "  - NAT rules: DNAT + MASQUERADE (using primary IP 10.14.105.254)"
  EOF
}

# Security group for NAT Gateway
resource "ibm_is_security_group" "nat_sg" {
  name           = "${var.project_name}-nat-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Allow all traffic from VPC subnet
resource "ibm_is_security_group_rule" "nat_sg_inbound_vpc" {
  group     = ibm_is_security_group.nat_sg.id
  direction = "inbound"
  remote    = ibm_is_subnet.subnet.ipv4_cidr_block
}

# Allow all traffic to Power VS
resource "ibm_is_security_group_rule" "nat_sg_outbound_power_vs" {
  group     = ibm_is_security_group.nat_sg.id
  direction = "outbound"
  remote    = "192.168.1.0/24"
}

# Allow SSH for management
resource "ibm_is_security_group_rule" "nat_sg_ssh" {
  group     = ibm_is_security_group.nat_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# Allow ICMP (ping) inbound for NAT gateway
resource "ibm_is_security_group_rule" "nat_sg_icmp" {
  group     = ibm_is_security_group.nat_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

# Allow all outbound for NAT gateway
resource "ibm_is_security_group_rule" "nat_sg_outbound_all" {
  group     = ibm_is_security_group.nat_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Floating IP for NAT Gateway (for management)
resource "ibm_is_floating_ip" "nat_gateway_fip" {
  name           = "${var.project_name}-nat-gateway-fip"
  target         = ibm_is_instance.nat_gateway.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# ==============================================================================
# Additional Power VS LPARs
# ==============================================================================

# RHEL 9 LPAR (192.168.1.7, appears as 10.14.105.7) - Substitute for AIX
resource "ibm_pi_instance" "rhel9_lpar" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.project_name}-rhel9-lpar"
  pi_image_id          = "385e32b9-e915-42af-bdc4-4e2ae4224087"  # RHEL9-SP6
  pi_key_pair_name     = ibm_pi_key.power_vs_ssh_key.name
  pi_sys_type          = "s922"
  pi_proc_type         = "shared"
  pi_processors        = 0.25
  pi_memory            = 2
  pi_storage_type      = "tier3"

  pi_network {
    network_id = ibm_pi_network.power_vs_network.network_id
    ip_address = "192.168.1.7"  # Manually assign IP matching last octet
  }

  depends_on = [
    ibm_pi_key.power_vs_ssh_key,
    ibm_pi_network.power_vs_network
  ]

  # Configure secondary IP for unified subnet (10.14.105.7)
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "sleep 60",
      "echo 'Configuring secondary IP 10.14.105.7/32 on env2 interface...'",
      "ip addr add 10.14.105.7/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses 10.14.105.7/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.7|10.14.105.7'"
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

# RHEL 8 LPAR (192.168.1.9, appears as 10.14.105.9) - Substitute for IBM i
resource "ibm_pi_instance" "rhel8_lpar" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.project_name}-rhel8-lpar"
  pi_image_id          = "d6b2c17c-2c2e-4352-aef7-115c3a9d933d"  # RHEL8-SP10
  pi_key_pair_name     = ibm_pi_key.power_vs_ssh_key.name
  pi_sys_type          = "s922"
  pi_proc_type         = "shared"
  pi_processors        = 0.25
  pi_memory            = 2
  pi_storage_type      = "tier3"

  pi_network {
    network_id = ibm_pi_network.power_vs_network.network_id
    ip_address = "192.168.1.9"  # Manually assign IP matching last octet
  }

  depends_on = [
    ibm_pi_key.power_vs_ssh_key,
    ibm_pi_network.power_vs_network
  ]

  # Configure secondary IP for unified subnet (10.14.105.9)
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "sleep 60",
      "echo 'Configuring secondary IP 10.14.105.9/32 on env2 interface...'",
      "ip addr add 10.14.105.9/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses 10.14.105.9/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.9|10.14.105.9'"
    ]
    
    connection {
      type                = "ssh"
      host                = self.pi_network[0].ip_address
      user                = "root"
      private_key         = file("${path.module}/ssh-keys/example-key.prv")
      timeout             = "15m"
      
      # Use VPC VSI as bastion/jump host to reach private Power VS network
      bastion_host        = ibm_is_floating_ip.vsi_fip.address
      bastion_user        = "ubuntu"
      bastion_private_key = file("${path.module}/ssh-keys/example-key.prv")
    }
  }
}