output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "availability_zones" {
  description = "List of Availability Zones."
  value       = data.aws_availability_zones.main.names
}
