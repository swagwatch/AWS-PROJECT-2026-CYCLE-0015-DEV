locals {
  # Common tags to be applied to all resources
  common_tags = merge(
    var.tags,
    {
      Name        = var.vpc_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  )

  # Resource naming pattern
  name_prefix = "${var.vpc_name}-${var.environment}"

  # Calculate NAT gateway count
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
}
