# ==============================================================================
# Unified Subnet Test Environment Outputs
# ==============================================================================

# ==============================================================================
# VPC VSIs
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

output "nat_gateway_ip" {
  description = "IP address of NAT Gateway"
  value       = ibm_is_instance.nat_gateway.primary_network_interface[0].primary_ip[0].address
}

output "nat_gateway_floating_ip" {
  description = "Floating IP for NAT Gateway (management)"
  value       = ibm_is_floating_ip.nat_gateway_fip.address
}

# ==============================================================================
# Power VS LPARs
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
    "10.14.105.4" = {
      type        = "VPC"
      system      = "Ubuntu VSI 1"
      actual_ip   = ibm_is_instance.ubuntu_vsi.primary_network_interface[0].primary_ip[0].address
      floating_ip = ibm_is_floating_ip.vsi_fip.address
    }
    "10.14.105.5" = {
      type      = "Power VS (via NAT)"
      system    = "CentOS LPAR"
      actual_ip = ibm_pi_instance.centos_lpar.pi_network[0].ip_address
      nat_ip    = "10.14.105.5"
    }
    "10.14.105.6" = {
      type      = "VPC"
      system    = "Ubuntu VSI 2"
      actual_ip = ibm_is_instance.ubuntu_vsi_2.primary_network_interface[0].primary_ip[0].address
    }
    "10.14.105.7" = {
      type      = "Power VS (via NAT)"
      system    = "RHEL 9 LPAR"
      actual_ip = ibm_pi_instance.rhel9_lpar.pi_network[0].ip_address
      nat_ip    = "10.14.105.7"
    }
    "10.14.105.8" = {
      type        = "VPC"
      system      = "Windows VSI"
      actual_ip   = ibm_is_instance.windows_vsi.primary_network_interface[0].primary_ip[0].address
      floating_ip = ibm_is_floating_ip.windows_fip.address
    }
    "10.14.105.9" = {
      type      = "Power VS (via NAT)"
      system    = "RHEL 8 LPAR"
      actual_ip = ibm_pi_instance.rhel8_lpar.pi_network[0].ip_address
      nat_ip    = "10.14.105.9"
    }
    "10.14.105.254" = {
      type        = "VPC"
      system      = "NAT Gateway"
      actual_ip   = ibm_is_instance.nat_gateway.primary_network_interface[0].primary_ip[0].address
      floating_ip = ibm_is_floating_ip.nat_gateway_fip.address
    }
  }
}

# ==============================================================================
# Connection Commands
# ==============================================================================

output "connection_commands" {
  description = "SSH/RDP commands for all systems"
  value = {
    ubuntu_vsi_1     = "ssh -i ~/.ssh/murali-key-n1-rsa.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}"
    ubuntu_vsi_2     = "ssh -i ~/.ssh/murali-key-n1-rsa.prv ubuntu@${ibm_is_instance.ubuntu_vsi_2.primary_network_interface[0].primary_ip[0].address} (from within VPC)"
    windows_vsi      = "RDP to ${ibm_is_floating_ip.windows_fip.address}"
    nat_gateway      = "ssh -i ~/.ssh/murali-key-n1-rsa.prv ubuntu@${ibm_is_floating_ip.nat_gateway_fip.address}"
    centos_lpar      = "ping 10.14.105.5 (from any VPC VSI)"
    rhel9_lpar       = "ping 10.14.105.7 (from any VPC VSI)"
    rhel8_lpar       = "ping 10.14.105.9 (from any VPC VSI)"
  }
}

# ==============================================================================
# Test Commands
# ==============================================================================

output "test_connectivity" {
  description = "Commands to test unified subnet connectivity"
  value = <<-EOT
    # From Ubuntu VSI 1 (10.14.105.4):
    ssh -i ~/.ssh/murali-key-n1-rsa.prv ubuntu@${ibm_is_floating_ip.vsi_fip.address}
    
    # Test connectivity to all systems:
    ping -c 4 10.14.105.6   # Ubuntu VSI 2
    ping -c 4 10.14.105.8   # Windows VSI
    ping -c 4 10.14.105.5   # CentOS LPAR (via NAT)
    ping -c 4 10.14.105.7   # RHEL 9 LPAR (via NAT)
    ping -c 4 10.14.105.9   # RHEL 8 LPAR (via NAT)
    
    # Verify routing:
    ip route | grep 10.14.105
    
    # Test SSH to Power VS systems (via NAT):
    ssh -i ~/.ssh/murali-key-n1-rsa.prv root@10.14.105.5
    ssh -i ~/.ssh/murali-key-n1-rsa.prv root@10.14.105.7
    ssh -i ~/.ssh/murali-key-n1-rsa.prv root@10.14.105.9
  EOT
}

output "nat_gateway_status" {
  description = "Commands to check NAT gateway status"
  value = <<-EOT
    # SSH to NAT Gateway:
    ssh -i ~/.ssh/murali-key-n1-rsa.prv ubuntu@${ibm_is_floating_ip.nat_gateway_fip.address}
    
    # Check NAT rules:
    sudo iptables -t nat -L -n -v
    
    # Check IP forwarding:
    sysctl net.ipv4.ip_forward
    
    # Check secondary IPs:
    ip addr show
    
    # Monitor NAT translations:
    sudo conntrack -L | grep 192.168.1
  EOT
}