variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for VPE reserved IPs"
  type        = list(string)
}

variable "cos_instance_crn" {
  description = "CRN of the Cloud Object Storage instance"
  type        = string
}

variable "tags" {
  description = "List of tags"
  type        = list(string)
  default     = []
}