# Local variables for ECS service

locals {
  environment  = "dev"
  service_name = "demo-app"

  common_tags = {
    Environment = local.environment
    Owner       = "platform-team"
    Service     = "ecs"
    ManagedBy   = "terraform"
  }
}
