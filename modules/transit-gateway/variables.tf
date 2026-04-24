variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the Transit Gateway"
  type        = string
}

variable "global_routing" {
  description = "Enable global routing for Transit Gateway"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_crn" {
  description = "CRN of the VPC"
  type        = string
}

variable "power_vs_crn" {
  description = "CRN of the Power VS workspace"
  type        = string
}

variable "tags" {
  description = "List of tags"
  type        = list(string)
  default     = []
}