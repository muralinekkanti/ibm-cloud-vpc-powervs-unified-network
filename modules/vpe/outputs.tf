output "vpe_gateway_id" {
  description = "ID of the Virtual Private Endpoint Gateway"
  value       = ibm_is_virtual_endpoint_gateway.vpe.id
}

output "vpe_gateway_name" {
  description = "Name of the Virtual Private Endpoint Gateway"
  value       = ibm_is_virtual_endpoint_gateway.vpe.name
}

output "vpe_gateway_crn" {
  description = "CRN of the Virtual Private Endpoint Gateway"
  value       = ibm_is_virtual_endpoint_gateway.vpe.crn
}

output "vpe_gateway_ips" {
  description = "Reserved IP addresses for the VPE Gateway"
  value = [
    for ip in ibm_is_virtual_endpoint_gateway.vpe.ips :
    {
      id      = ip.id
      address = ip.address
      name    = ip.name
    }
  ]
}

output "vpe_security_group_id" {
  description = "ID of the VPE security group"
  value       = ibm_is_security_group.vpe_sg.id
}