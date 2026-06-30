locals {
  environment = "dev"
  owner       = "platform-team"

  # Common tags for dev environment
  common_tags = {
    Project     = "terraform-vpc-module"
    ManagedBy   = "Terraform"
    Environment = local.environment
  }
}
