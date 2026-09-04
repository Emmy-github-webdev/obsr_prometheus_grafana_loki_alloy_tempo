output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.observastack_vpc.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.observastack_vpc.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.observastack_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for subnet in aws_subnet.pub_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = [for subnet in aws_subnet.priv_subnet : subnet.id]
}

output "database_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = [for subnet in aws_subnet.database : subnet.id]
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets."
  value       = [for subnet in aws_subnet.pub_subnet : subnet.arn]
}

output "private_subnet_arns" {
  description = "ARNs of the private application subnets."
  value       = [for subnet in aws_subnet.priv_subnet : subnet.arn]
}

output "database_subnet_arns" {
  description = "ARNs of the database subnets."
  value       = [for subnet in aws_subnet.database : subnet.arn]
}

output "availability_zones" {
  description = "Availability Zones used by the VPC."
  value       = var.availability_zones
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways."
  value       = [for nat in aws_nat_gateway.nat_gateway : nat.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.observastack_igw.id
}

output "flow_log_id" {
  description = "VPC Flow Log ID."
  value       = try(aws_flow_log.flow_log[0].id, null)
}