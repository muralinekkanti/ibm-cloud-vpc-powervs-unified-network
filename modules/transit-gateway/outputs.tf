output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.id
}

output "transit_gateway_name" {
  description = "Name of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.name
}

output "transit_gateway_crn" {
  description = "CRN of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.crn
}

output "transit_gateway_status" {
  description = "Status of the Transit Gateway"
  value       = ibm_tg_gateway.transit_gateway.status
}

output "vpc_connection_id" {
  description = "ID of the VPC connection"
  value       = ibm_tg_connection.vpc_connection.connection_id
}

output "vpc_connection_status" {
  description = "Status of the VPC connection"
  value       = ibm_tg_connection.vpc_connection.status
}

output "power_vs_connection_id" {
  description = "ID of the Power VS connection"
  value       = ibm_tg_connection.power_vs_connection.connection_id
}

output "power_vs_connection_status" {
  description = "Status of the Power VS connection"
  value       = ibm_tg_connection.power_vs_connection.status
}

output "connection_ids" {
  description = "Map of all connection IDs"
  value = {
    vpc      = ibm_tg_connection.vpc_connection.connection_id
    power_vs = ibm_tg_connection.power_vs_connection.connection_id
  }
}