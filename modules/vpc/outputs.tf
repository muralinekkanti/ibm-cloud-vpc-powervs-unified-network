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

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = ibm_is_subnet.subnet[*].id
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = ibm_is_subnet.subnet[*].ipv4_cidr_block
}

output "subnet_zones" {
  description = "List of subnet zones"
  value       = ibm_is_subnet.subnet[*].zone
}

output "security_group_id" {
  description = "ID of the security group"
  value       = ibm_is_security_group.sg.id
}

output "network_acl_id" {
  description = "ID of the network ACL"
  value       = ibm_is_network_acl.acl.id
}

output "public_gateway_ids" {
  description = "List of public gateway IDs"
  value       = var.enable_public_gateway ? ibm_is_public_gateway.pgw[*].id : []
}