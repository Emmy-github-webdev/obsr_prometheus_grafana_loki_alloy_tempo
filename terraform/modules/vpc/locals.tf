locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "network"
    },
    var.tags
  )

  public_subnet_count = length(var.availability_zones)

  private_subnet_count = length(var.availability_zones)

  database_subnet_count = length(var.availability_zones)
}