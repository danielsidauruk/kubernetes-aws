variable "primary_region" {
  description = "Primary AWS region."
  type        = string
}

variable "cidr_block" {
  type        = string
  description = "CIDR block."
}

variable "az_count" {
  description = "Number of Availability Zones."
  type        = number
}
