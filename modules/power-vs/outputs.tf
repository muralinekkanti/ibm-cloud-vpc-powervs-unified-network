output "workspace_id" {
  description = "ID of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.guid
}

output "workspace_crn" {
  description = "CRN of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.crn
}

output "workspace_name" {
  description = "Name of the Power VS workspace"
  value       = ibm_resource_instance.power_vs_workspace.name
}

output "network_id" {
  description = "ID of the Power VS private network"
  value       = ibm_pi_network.private_network.network_id
}

output "network_cidr" {
  description = "CIDR block of the Power VS network"
  value       = ibm_pi_network.private_network.pi_cidr
}

output "network_vlan_id" {
  description = "VLAN ID of the Power VS network"
  value       = ibm_pi_network.private_network.vlan_id
}

output "instance_ids" {
  description = "List of Power VS instance IDs"
  value       = ibm_pi_instance.instance[*].instance_id
}

output "instance_names" {
  description = "List of Power VS instance names"
  value       = ibm_pi_instance.instance[*].pi_instance_name
}

output "instance_ips" {
  description = "List of Power VS instance IP addresses"
  value = [
    for instance in ibm_pi_instance.instance :
    instance.pi_network[0].ip_address
  ]
}

output "instance_details" {
  description = "Detailed information about Power VS instances"
  value = [
    for idx, instance in ibm_pi_instance.instance : {
      name       = instance.pi_instance_name
      id         = instance.instance_id
      ip_address = instance.pi_network[0].ip_address
      status     = instance.status
      processors = instance.pi_processors
      memory     = instance.pi_memory
      proc_type  = instance.pi_proc_type
      sys_type   = instance.pi_sys_type
    }
  ]
}

output "ssh_key_name" {
  description = "Name of the SSH key"
  value       = var.ssh_public_key != "" ? ibm_pi_key.ssh_key[0].pi_key_name : null
}

output "volume_ids" {
  description = "List of storage volume IDs"
  value       = ibm_pi_volume.storage[*].volume_id
}