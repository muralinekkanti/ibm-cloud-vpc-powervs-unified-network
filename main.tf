# Data source to get existing resource group
data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# ==============================================================================
# Local Variables - Calculated IP Addresses
# ==============================================================================

locals {
  # Calculate IPs dynamically from subnet CIDR
  # Odd numbers (5, 7, 9) are reserved for Power VS LPARs
  centos_lpar_ip  = cidrhost(var.vpc_subnet_cidr, var.centos_lpar_ip_offset)
  rhel9_lpar_ip   = cidrhost(var.vpc_subnet_cidr, var.rhel9_lpar_ip_offset)
  rhel8_lpar_ip   = cidrhost(var.vpc_subnet_cidr, var.rhel8_lpar_ip_offset)
  
  # Gateway IP (first usable IP in subnet)
  gateway_ip      = cidrhost(var.vpc_subnet_cidr, 1)
  
  # VPC VSI IPs - using consecutive even numbers to avoid conflict with odd-numbered LPAR IPs
  ubuntu_vsi_1_ip = cidrhost(var.vpc_subnet_cidr, 4)   # 10.14.105.4
  ubuntu_vsi_2_ip = cidrhost(var.vpc_subnet_cidr, 6)   # 10.14.105.6
  windows_vsi_ip  = cidrhost(var.vpc_subnet_cidr, 8)   # 10.14.105.8
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
  cidr = var.vpc_subnet_cidr
}

# Create subnet in first availability zone
resource "ibm_is_subnet" "subnet" {
  name            = "${var.project_name}-subnet-1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.region}-1"
  ipv4_cidr_block = var.vpc_subnet_cidr
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
  remote    = var.power_vs_network_cidr
}

# Allow all outbound traffic
resource "ibm_is_security_group_rule" "vsi_sg_outbound" {
  group     = ibm_is_security_group.vsi_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# ==============================================================================
# SSH Key Generation (OS-independent, created by Terraform)
# ==============================================================================

# Generate primary SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate secondary SSH key pair
resource "tls_private_key" "secondary_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save primary private key to local file (for SSH access)
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/terraform-generated-key.pem"
  file_permission = "0600"
}

# Save secondary private key to local file (for SSH access)
resource "local_file" "secondary_private_key" {
  content         = tls_private_key.secondary_ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/terraform-generated-secondary-key.pem"
  file_permission = "0600"
}

# Create SSH key for VPC using generated key
resource "ibm_is_ssh_key" "vpc_ssh_key" {
  name           = "${var.project_name}-vpc-key"
  public_key     = tls_private_key.ssh_key.public_key_openssh
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

# Create secondary SSH key for VPC
resource "ibm_is_ssh_key" "secondary_ssh_key" {
  name           = "${var.project_name}-secondary-key"
  public_key     = tls_private_key.secondary_ssh_key.public_key_openssh
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
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
  keys           = [ibm_is_ssh_key.vpc_ssh_key.id, ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
    primary_ip {
      address = local.ubuntu_vsi_1_ip
      name    = "${var.project_name}-ubuntu-vsi-1-ip"
    }
  }

  user_data = <<-EOF
    #cloud-config
    write_files:
      - path: /tmp/example-key.prv
        permissions: '0600'
        content: |
          ${indent(6, file("${path.module}/ssh-keys/example-key.prv"))}
      - path: /etc/netplan/99-static-routes.yaml
        permissions: '0644'
        content: |
          network:
            version: 2
            ethernets:
              ens3:
                routes:
                  - to: ${local.centos_lpar_ip}/32
                    via: ${local.gateway_ip}
                  - to: ${local.rhel9_lpar_ip}/32
                    via: ${local.gateway_ip}
                  - to: ${local.rhel8_lpar_ip}/32
                    via: ${local.gateway_ip}
    
    runcmd:
      - mkdir -p /home/ubuntu/.ssh
      - mv /tmp/example-key.prv /home/ubuntu/.ssh/
      - chown -R ubuntu:ubuntu /home/ubuntu/.ssh
      - chmod 700 /home/ubuntu/.ssh
      - chmod 600 /home/ubuntu/.ssh/example-key.prv
      - netplan apply
      - echo "Ubuntu VSI 1 initialization complete"
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
# Additional Test VSIs
# ==============================================================================

# Second Ubuntu VSI
resource "ibm_is_instance" "ubuntu_vsi_2" {
  name           = "${var.project_name}-ubuntu-vsi-2"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu.id
  keys           = [ibm_is_ssh_key.vpc_ssh_key.id, ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = concat(var.tags, ["x86", "ubuntu"])

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
    primary_ip {
      address = local.ubuntu_vsi_2_ip
      name    = "${var.project_name}-ubuntu-vsi-2-ip"
    }
  }

  user_data = <<-EOF
    #cloud-config
    write_files:
      - path: /tmp/example-key.prv
        permissions: '0600'
        content: |
          ${indent(6, file("${path.module}/ssh-keys/example-key.prv"))}
      - path: /etc/netplan/99-static-routes.yaml
        permissions: '0644'
        content: |
          network:
            version: 2
            ethernets:
              ens3:
                routes:
                  - to: ${local.centos_lpar_ip}/32
                    via: ${local.gateway_ip}
                  - to: ${local.rhel9_lpar_ip}/32
                    via: ${local.gateway_ip}
                  - to: ${local.rhel8_lpar_ip}/32
                    via: ${local.gateway_ip}
    
    runcmd:
      - mkdir -p /home/ubuntu/.ssh
      - mv /tmp/example-key.prv /home/ubuntu/.ssh/
      - chown -R ubuntu:ubuntu /home/ubuntu/.ssh
      - chmod 700 /home/ubuntu/.ssh
      - chmod 600 /home/ubuntu/.ssh/example-key.prv
      - netplan apply
      - echo "Ubuntu VSI 2 initialization complete"
  EOF
}

# Get Windows Server image
data "ibm_is_image" "windows" {
  name = "ibm-windows-server-2022-full-standard-amd64-12"
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

# Allow outbound to metadata service (required for user-data execution)
resource "ibm_is_security_group_rule" "windows_sg_metadata" {
  group     = ibm_is_security_group.windows_sg.id
  direction = "outbound"
  remote    = "169.254.169.254/32"
  tcp {
    port_min = 80
    port_max = 80
  }
}

# Allow all other outbound traffic
resource "ibm_is_security_group_rule" "windows_sg_outbound" {
  group     = ibm_is_security_group.windows_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Windows VSI
resource "ibm_is_instance" "windows_vsi" {
  name           = "${var.project_name}-windows-vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  profile        = "bx2-2x8"  # Windows needs more RAM
  image          = data.ibm_is_image.windows.id
  keys           = [ibm_is_ssh_key.vpc_ssh_key.id, ibm_is_ssh_key.secondary_ssh_key.id]
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = concat(var.tags, ["x86", "windows"])

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.vsi_sg.id, ibm_is_security_group.windows_sg.id]
    primary_ip {
      address = local.windows_vsi_ip
    }
  }
  # CRITICAL: This enables the 169.254.169.254 endpoint
  metadata_service {
    enabled            = true
    protocol           = "http"
    response_hop_limit = 10
  }
user_data = <<-EOF
#cloud-config
runcmd:
  - route add 169.254.169.254 mask 255.255.255.255 ${local.gateway_ip} metric 1
  - route add ${local.centos_lpar_ip} mask 255.255.255.255 ${local.gateway_ip} -p
  - route add ${local.rhel9_lpar_ip}  mask 255.255.255.255 ${local.gateway_ip} -p
  - route add ${local.rhel8_lpar_ip}  mask 255.255.255.255 ${local.gateway_ip} -p
EOF

}

# Floating IP for Windows VSI
resource "ibm_is_floating_ip" "windows_fip" {
  name           = "${var.project_name}-windows-fip"
  target         = ibm_is_instance.windows_vsi.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}


# ==============================================================================
# Power VS Resources
# ==============================================================================

# Create Power VS workspace
resource "ibm_resource_instance" "power_vs_workspace" {
  name              = "${var.project_name}-workspace"
  service           = "power-iaas"
  plan              = "power-virtual-server-group"
  location          = var.power_vs_zone
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Create Power VS SSH key (uses same generated key as VPC for consistency)
resource "ibm_pi_key" "power_vs_ssh_key" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_key_name          = "${var.project_name}-power-key"
  pi_ssh_key           = tls_private_key.ssh_key.public_key_openssh
}

# Create secondary Power VS SSH key (uses same generated secondary key as VPC)
resource "ibm_pi_key" "power_vs_secondary_ssh_key" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_key_name          = "${var.project_name}-power-secondary-key"
  pi_ssh_key           = tls_private_key.secondary_ssh_key.public_key_openssh
}

# Create Power VS private network
resource "ibm_pi_network" "power_vs_network" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_network_name      = "${var.project_name}-power-network"
  pi_network_type      = "vlan"
  pi_cidr              = var.power_vs_network_cidr
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
  
  # Filter for RHEL 9 images
  rhel9_images = [for image in data.ibm_pi_catalog_images.catalog_images.images :
    image if can(regex("(?i)rhel.*9", image.name))
  ]
  
  # Filter for RHEL 8 images
  rhel8_images = [for image in data.ibm_pi_catalog_images.catalog_images.images :
    image if can(regex("(?i)rhel.*8", image.name))
  ]
  
  # Use the first image found for each OS, or fail if none available
  centos_image_id   = length(local.centos_images) > 0 ? local.centos_images[0].image_id : null
  centos_image_name = length(local.centos_images) > 0 ? local.centos_images[0].name : "No CentOS image found"
  rhel9_image_id    = length(local.rhel9_images) > 0 ? local.rhel9_images[0].image_id : null
  rhel8_image_id    = length(local.rhel8_images) > 0 ? local.rhel8_images[0].image_id : null
}

# Power VS Network Routes for unified subnet addressing
# These routes enable LPAR-to-LPAR communication via 10.14.105.x addresses
resource "ibm_pi_route" "centos_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-centos-lpar"
  pi_destination       = local.centos_lpar_ip
  pi_next_hop          = ibm_pi_instance.centos_lpar.pi_network[0].ip_address
  pi_enabled           = true
  
  depends_on = [
    ibm_pi_network.power_vs_network,
    ibm_pi_instance.centos_lpar
  ]
}

resource "ibm_pi_route" "rhel9_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-rhel9-lpar"
  pi_destination       = local.rhel9_lpar_ip
  pi_next_hop          = ibm_pi_instance.rhel9_lpar.pi_network[0].ip_address
  pi_enabled           = true
  
  depends_on = [
    ibm_pi_network.power_vs_network,
    ibm_pi_instance.rhel9_lpar
  ]
}

resource "ibm_pi_route" "rhel8_lpar_route" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_name              = "route-rhel8-lpar"
  pi_destination       = local.rhel8_lpar_ip
  pi_next_hop          = ibm_pi_instance.rhel8_lpar.pi_network[0].ip_address
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

  # Configure secondary IP for unified subnet (${local.centos_lpar_ip})
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "sleep 60",
      "echo 'Configuring secondary IP ${local.centos_lpar_ip}/32 on env2 interface...'",
      "ip addr add ${local.centos_lpar_ip}/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses ${local.centos_lpar_ip}/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.5|${local.centos_lpar_ip}'"
    ]
    
    connection {
      type                = "ssh"
      host                = self.pi_network[0].ip_address
      user                = "root"
      private_key         = tls_private_key.ssh_key.private_key_pem
      timeout             = "15m"
      
      # Use VPC VSI as bastion/jump host to reach private Power VS network
      bastion_host        = ibm_is_floating_ip.vsi_fip.address
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

# ==============================================================================
# ==============================================================================
# Additional Power VS LPARs (Test Environment)
# ==============================================================================

# RHEL 9 LPAR (192.168.1.7, appears as 10.14.105.7) - Substitute for AIX
resource "ibm_pi_instance" "rhel9_lpar" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.project_name}-rhel9-lpar"
  pi_image_id          = local.rhel9_image_id  # Dynamically selected from catalog
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
      "echo 'Configuring secondary IP ${local.rhel9_lpar_ip}/32 on env2 interface...'",
      "ip addr add ${local.rhel9_lpar_ip}/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses ${local.rhel9_lpar_ip}/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.7|${local.rhel9_lpar_ip}'"
    ]
    
    connection {
      type                = "ssh"
      host                = self.pi_network[0].ip_address
      user                = "root"
      private_key         = tls_private_key.ssh_key.private_key_pem
      timeout             = "15m"
      
      # Use VPC VSI as bastion/jump host to reach private Power VS network
      bastion_host        = ibm_is_floating_ip.vsi_fip.address
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

# RHEL 8 LPAR (192.168.1.9, appears as 10.14.105.9) - Substitute for IBM i
resource "ibm_pi_instance" "rhel8_lpar" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.project_name}-rhel8-lpar"
  pi_image_id          = local.rhel8_image_id  # Dynamically selected from catalog
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
      "echo 'Configuring secondary IP ${local.rhel8_lpar_ip}/32 on env2 interface...'",
      "ip addr add ${local.rhel8_lpar_ip}/32 dev env2 || true",
      "CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1)",
      "if [ -n \"$CONNECTION\" ]; then",
      "  nmcli connection modify \"$CONNECTION\" +ipv4.addresses ${local.rhel8_lpar_ip}/32",
      "  nmcli connection up \"$CONNECTION\"",
      "fi",
      "echo 'Secondary IP configuration complete'",
      "ip addr show env2 | grep -E '192.168.1.9|${local.rhel8_lpar_ip}'"
    ]
    
    connection {
      type                = "ssh"
      host                = self.pi_network[0].ip_address
      user                = "root"
      private_key         = tls_private_key.ssh_key.private_key_pem
      timeout             = "15m"
      
      # Use VPC VSI as bastion/jump host to reach private Power VS network
      bastion_host        = ibm_is_floating_ip.vsi_fip.address
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

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