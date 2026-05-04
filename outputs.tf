# ==============================================================================
# VPC Outputs
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = ibm_is_vpc.vpc.id
}

output "vpc_crn" {
  description = "CRN of the VPC"
  value       = ibm_is_vpc.vpc.crn
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = ibm_is_vpc.vpc.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = ibm_is_subnet.subnet.id
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = ibm_is_subnet.subnet.ipv4_cidr_block
}

# ==============================================================================
# VSI Outputs
# ==============================================================================

output "vsi_id" {
  description = "ID of the Ubuntu VSI"
  value       = ibm_is_instance.ubuntu_vsi.id
}

output "vsi_name" {
  description = "Name of the Ubuntu VSI"
  value       = ibm_is_instance.ubuntu_vsi.name
}

output "vsi_private_ip" {
  description = "Private IP address of the VSI"
  value       = ibm_is_instance.ubuntu_vsi.primary_network_interface[0].primary_ipv4_address
}

output "vsi_floating_ip" {
  description = "Floating IP address of the VSI"
  value       = ibm_is_floating_ip.vsi_fip.address
}

output "ssh_connection_vsi" {
  description = "SSH command to connect to the VSI"
  value       = "ssh -i ~/.ssh/example-key.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}"
}

# ==============================================================================
# Power VS Outputs
# ==============================================================================

output "power_vs_workspace_id" {
  description = "ID of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.id
}

output "power_vs_workspace_guid" {
  description = "GUID of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.guid
}

output "power_vs_workspace_crn" {
  description = "CRN of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.crn
}

output "power_vs_network_id" {
  description = "ID of the Power VS network"
  value       = ibm_pi_network.power_vs_network.network_id
}

output "power_vs_network_cidr" {
  description = "CIDR of the Power VS network"
  value       = ibm_pi_network.power_vs_network.pi_cidr
}

output "centos_image_id" {
  description = "Dynamically selected CentOS image ID"
  value       = local.centos_image_id
}

output "centos_image_name" {
  description = "Dynamically selected CentOS image name"
  value       = local.centos_image_name
}

output "lpar_id" {
  description = "ID of the CentOS LPAR"
  value       = ibm_pi_instance.centos_lpar.instance_id
}

output "lpar_name" {
  description = "Name of the CentOS LPAR"
  value       = ibm_pi_instance.centos_lpar.pi_instance_name
}

output "lpar_ip" {
  description = "IP address of the CentOS LPAR"
  value       = ibm_pi_instance.centos_lpar.pi_network[0].ip_address
}

output "ssh_connection_lpar" {
  description = "SSH command to connect to the LPAR (from VSI)"
  value       = "ssh -i ~/.ssh/example-key.prv root@${ibm_pi_instance.centos_lpar.pi_network[0].ip_address}"
}

# ==============================================================================
# Transit Gateway Outputs
# ==============================================================================

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.id
}

output "transit_gateway_crn" {
  description = "CRN of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.crn
}

output "transit_gateway_name" {
  description = "Name of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.name
}

# ==============================================================================
# General Outputs
# ==============================================================================

output "region" {
  description = "IBM Cloud region"
  value       = var.region
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = data.ibm_resource_group.resource_group.id
}

# ==============================================================================
# Connection Information
# ==============================================================================


output "connectivity_summary" {
  description = "Summary of network connectivity"
  value = {
    vpc_subnet        = ibm_is_subnet.subnet.ipv4_cidr_block
    power_vs_network  = ibm_pi_network.power_vs_network.pi_cidr
    vsi_private_ip    = ibm_is_instance.ubuntu_vsi.primary_network_interface[0].primary_ipv4_address
    vsi_floating_ip   = ibm_is_floating_ip.vsi_fip.address
    transit_gateway   = ibm_tg_gateway.transit_gateway.name
  }
}

# ==============================================================================
# Additional VPC VSIs
# ==============================================================================

output "ubuntu_vsi_2_ip" {
  description = "IP address of Ubuntu VSI 2"
  value       = ibm_is_instance.ubuntu_vsi_2.primary_network_interface[0].primary_ip[0].address
}

output "windows_vsi_ip" {
  description = "IP address of Windows VSI"
  value       = ibm_is_instance.windows_vsi.primary_network_interface[0].primary_ip[0].address
}

output "windows_vsi_floating_ip" {
  description = "Floating IP for Windows VSI (RDP access)"
  value       = ibm_is_floating_ip.windows_fip.address
}

# ==============================================================================
# Additional Power VS LPARs
# ==============================================================================

output "rhel9_lpar_id" {
  description = "ID of RHEL 9 LPAR"
  value       = ibm_pi_instance.rhel9_lpar.instance_id
}

output "rhel9_lpar_ip" {
  description = "IP address of RHEL 9 LPAR"
  value       = ibm_pi_instance.rhel9_lpar.pi_network[0].ip_address
}

output "rhel8_lpar_id" {
  description = "ID of RHEL 8 LPAR"
  value       = ibm_pi_instance.rhel8_lpar.instance_id
}

output "rhel8_lpar_ip" {
  description = "IP address of RHEL 8 LPAR"
  value       = ibm_pi_instance.rhel8_lpar.pi_network[0].ip_address
}

# ==============================================================================
# Unified Subnet Mapping
# ==============================================================================

output "unified_subnet_map" {
  description = "Complete mapping of unified subnet IPs"
  value = {
    (local.ubuntu_vsi_1_ip) = {
      type        = "VPC"
      system      = "Ubuntu VSI 1"
      actual_ip   = ibm_is_instance.ubuntu_vsi.primary_network_interface[0].primary_ip[0].address
      floating_ip = ibm_is_floating_ip.vsi_fip.address
    }
    (local.centos_lpar_ip) = {
      type       = "Power VS (via IP Alias)"
      system     = "CentOS LPAR"
      actual_ip  = ibm_pi_instance.centos_lpar.pi_network[0].ip_address
      unified_ip = local.centos_lpar_ip
    }
    (local.ubuntu_vsi_2_ip) = {
      type      = "VPC"
      system    = "Ubuntu VSI 2"
      actual_ip = ibm_is_instance.ubuntu_vsi_2.primary_network_interface[0].primary_ip[0].address
    }
    (local.rhel9_lpar_ip) = {
      type       = "Power VS (via IP Alias)"
      system     = "RHEL 9 LPAR"
      actual_ip  = ibm_pi_instance.rhel9_lpar.pi_network[0].ip_address
      unified_ip = local.rhel9_lpar_ip
    }
    (local.windows_vsi_ip) = {
      type        = "VPC"
      system      = "Windows VSI"
      actual_ip   = ibm_is_instance.windows_vsi.primary_network_interface[0].primary_ip[0].address
      floating_ip = ibm_is_floating_ip.windows_fip.address
    }
    (local.rhel8_lpar_ip) = {
      type       = "Power VS (via IP Alias)"
      system     = "RHEL 8 LPAR"
      actual_ip  = ibm_pi_instance.rhel8_lpar.pi_network[0].ip_address
      unified_ip = local.rhel8_lpar_ip
    }
  }
}

# ==============================================================================
# Connection Commands
# ==============================================================================

output "connection_commands" {
  description = "SSH/RDP commands for all systems"
  value = {
    ubuntu_vsi_1 = "ssh -i ~/.ssh/example-key.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}"
    ubuntu_vsi_2 = "ssh -i ~/.ssh/example-key.prv ubuntu@${ibm_is_instance.ubuntu_vsi_2.primary_network_interface[0].primary_ip[0].address} (from within VPC)"
    windows_vsi  = "RDP to ${ibm_is_floating_ip.windows_fip.address}"
    centos_lpar  = "ping ${local.centos_lpar_ip} (from any VPC VSI)"
    rhel9_lpar   = "ping ${local.rhel9_lpar_ip} (from any VPC VSI)"
    rhel8_lpar   = "ping ${local.rhel8_lpar_ip} (from any VPC VSI)"
  }
}

# ==============================================================================
# Test Commands
# ==============================================================================

output "test_connectivity" {
  description = "Commands to test unified subnet connectivity"
  value = <<-EOT
    # From Ubuntu VSI 1 (${local.ubuntu_vsi_1_ip}):
    ssh -i ~/.ssh/example-key.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}
    
    # Test connectivity to all systems:
    ping -c 4 ${local.ubuntu_vsi_2_ip}   # Ubuntu VSI 2
    ping -c 4 ${local.windows_vsi_ip}   # Windows VSI
    ping -c 4 ${local.centos_lpar_ip}   # CentOS LPAR (via IP alias)
    ping -c 4 ${local.rhel9_lpar_ip}   # RHEL 9 LPAR (via IP alias)
    ping -c 4 ${local.rhel8_lpar_ip}   # RHEL 8 LPAR (via IP alias)
    
    # Verify routing:
    ip route | grep 10.14.105
    
    # Test SSH to Power VS systems (via IP alias):
    ssh -i ~/.ssh/example-key.prv root@${local.centos_lpar_ip}
    ssh -i ~/.ssh/example-key.prv root@${local.rhel9_lpar_ip}
    ssh -i ~/.ssh/example-key.prv root@${local.rhel8_lpar_ip}
  EOT
}

output "ip_alias_status" {
  description = "Commands to verify IP alias configuration"
  value = <<-EOT
    # SSH to Power VS LPARs and check IP aliases:
    ssh -i ~/.ssh/example-key.prv root@192.168.1.5 'ip addr show | grep 10.14.105'
    ssh -i ~/.ssh/example-key.prv root@192.168.1.7 'ip addr show | grep 10.14.105'
    ssh -i ~/.ssh/example-key.prv root@192.168.1.9 'ip addr show | grep 10.14.105'
    
    # Test connectivity from VPC VSI:
    ssh -i ~/.ssh/example-key.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}
    ping -c 4 10.14.105.5  # CentOS LPAR
    ping -c 4 10.14.105.7  # RHEL 9 LPAR
    ping -c 4 10.14.105.9  # RHEL 8 LPAR
  EOT
}