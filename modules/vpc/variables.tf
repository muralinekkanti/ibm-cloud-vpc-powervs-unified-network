variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
}

variable "enable_public_gateway" {
  description = "Enable public gateway for subnets"
  type        = bool
  default     = false
}

variable "power_vs_cidr" {
  description = "CIDR block for Power VS network (for security group rules)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "List of tags"
  type        = list(string)
  default     = []
}