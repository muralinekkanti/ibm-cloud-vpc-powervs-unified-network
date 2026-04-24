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
    # lpar_ip           = ibm_pi_instance.centos_lpar.pi_network[0].ip_address
    transit_gateway   = ibm_tg_gateway.transit_gateway.name
  }
}