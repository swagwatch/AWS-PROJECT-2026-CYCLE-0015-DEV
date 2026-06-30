package terraform.aws.ecs

# Evaluate Terraform plan JSON (terraform show -json plan.tfplan)
# Provides:
# - deny: CRITICAL violations that must fail the pipeline
# - warn: non-blocking warnings
# - info: informational findings

# Helper: return resource changes for a given type that are created or updated
resource_changes_by_type(res_type) := array.concat(creates, updates) if {
  creates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "create")
  ]
  updates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "update")
  ]
}

# Helper: get tags from after object
get_tags(after) = tags_out if {
  tags := after.tags
  tags_out := tags
} else = tags_all_out if {
  tags_all := after.tags_all
  tags_all_out := tags_all
} else = {} if {
  true
}

# Helper: check if a list contains a value
array_contains(arr, v) if {
  some i
  arr[i] == v
}

# ------------------------
# DENY Rules (Security Best Practices - CRITICAL)
# ------------------------

# Required tags check for ECS clusters
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_cluster")[_]
  after := resource.change.after
  tags := get_tags(after)

  required_tags := ["Environment", "Owner"]
  missing_tag := required_tags[_]
  not tags[missing_tag]

  msg := sprintf("ECS Cluster '%s' is missing required tag: '%s'. Required tags: %v", [
    after.name,
    missing_tag,
    required_tags
  ])
}

# Required tags check for ECS services
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_service")[_]
  after := resource.change.after
  tags := get_tags(after)

  required_tags := ["Environment", "Owner"]
  missing_tag := required_tags[_]
  not tags[missing_tag]

  msg := sprintf("ECS Service '%s' is missing required tag: '%s'. Required tags: %v", [
    after.name,
    missing_tag,
    required_tags
  ])
}

# Required tags check for ECS task definitions
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after
  tags := get_tags(after)

  required_tags := ["Environment", "Owner"]
  missing_tag := required_tags[_]
  not tags[missing_tag]

  msg := sprintf("ECS Task Definition '%s' is missing required tag: '%s'. Required tags: %v", [
    after.family,
    missing_tag,
    required_tags
  ])
}

# Fargate tasks must use awsvpc network mode
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after

  compatibilities := after.requires_compatibilities
  array_contains(compatibilities, "FARGATE")

  after.network_mode != "awsvpc"

  msg := sprintf("ECS Task Definition '%s' requires FARGATE but does not use 'awsvpc' network mode. Fargate requires awsvpc network mode.", [
    after.family
  ])
}

# Task definitions for Fargate must have execution role
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after

  compatibilities := after.requires_compatibilities
  array_contains(compatibilities, "FARGATE")

  not after.execution_role_arn

  msg := sprintf("ECS Task Definition '%s' requires FARGATE but does not have an execution_role_arn. Fargate tasks require an execution role.", [
    after.family
  ])
}

# Security groups must not allow unrestricted ingress on sensitive ports
deny contains msg if {
  resource := resource_changes_by_type("aws_security_group_rule")[_]
  after := resource.change.after

  after.type == "ingress"

  # Check for 0.0.0.0/0 or ::/0
  cidr := after.cidr_blocks[_]
  cidr == "0.0.0.0/0"

  # Sensitive ports (SSH, RDP, database ports, etc.)
  sensitive_ports := [22, 3389, 3306, 5432, 1433, 27017, 6379, 9200]
  port := sensitive_ports[_]

  after.from_port <= port
  after.to_port >= port

  msg := sprintf("Security group rule allows unrestricted access (0.0.0.0/0) to sensitive port %d. Restrict access to specific IP ranges or security groups.", [
    port
  ])
}

# CloudWatch log groups should have encryption enabled for production
deny contains msg if {
  resource := resource_changes_by_type("aws_cloudwatch_log_group")[_]
  after := resource.change.after
  tags := get_tags(after)

  # Check if this is a production environment
  tags["Environment"] == "prod"

  # Check if encryption is not configured
  not after.kms_key_id

  msg := sprintf("CloudWatch Log Group '%s' in production environment does not have encryption enabled. Enable KMS encryption for production logs.", [
    after.name
  ])
}

# ECS services with public IP should be intentional
deny contains msg if {
  resource := resource_changes_by_type("aws_ecs_service")[_]
  after := resource.change.after

  network_config := after.network_configuration[_]
  network_config.assign_public_ip == true

  tags := get_tags(after)
  not tags["PublicAccess"]

  msg := sprintf("ECS Service '%s' assigns public IPs but does not have 'PublicAccess' tag for documentation. Add tag PublicAccess=true if this is intentional.", [
    after.name
  ])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# Recommend FARGATE_SPOT for cost savings in non-production
warn contains msg if {
  resource := resource_changes_by_type("aws_ecs_service")[_]
  after := resource.change.after
  tags := get_tags(after)

  # Only for non-production
  tags["Environment"] != "prod"

  # Using FARGATE launch type
  after.launch_type == "FARGATE"

  # Not using capacity provider strategy (which could include FARGATE_SPOT)
  not after.capacity_provider_strategy

  msg := sprintf("ECS Service '%s' in non-production environment uses FARGATE. Consider using FARGATE_SPOT capacity provider for cost savings.", [
    after.name
  ])
}

# Warn about high CPU allocation
warn contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after

  # CPU is a string in the API (e.g., "4096")
  cpu := to_number(after.cpu)
  cpu >= 4096

  msg := sprintf("ECS Task Definition '%s' allocates %s CPU units (4+ vCPUs). Ensure this level of resources is necessary to avoid unnecessary costs.", [
    after.family,
    after.cpu
  ])
}

# Warn about high memory allocation
warn contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after

  # Memory is a string in the API (e.g., "8192")
  memory := to_number(after.memory)
  memory >= 16384

  msg := sprintf("ECS Task Definition '%s' allocates %s MiB memory (16+ GB). Ensure this level of resources is necessary to avoid unnecessary costs.", [
    after.family,
    after.memory
  ])
}

# Warn about missing Container Insights
warn contains msg if {
  resource := resource_changes_by_type("aws_ecs_cluster")[_]
  after := resource.change.after

  # Check if container insights is not enabled
  not has_container_insights_enabled(after.setting)

  msg := sprintf("ECS Cluster '%s' does not have Container Insights enabled. Enable Container Insights for better observability and monitoring.", [
    after.name
  ])
}

# Helper function to check if Container Insights is enabled
has_container_insights_enabled(settings) if {
  setting := settings[_]
  setting.name == "containerInsights"
  setting.value == "enabled"
}

# Warn about missing log retention
warn contains msg if {
  resource := resource_changes_by_type("aws_cloudwatch_log_group")[_]
  after := resource.change.after

  # Check if retention is not set or is too long
  retention := after.retention_in_days
  retention > 30

  tags := get_tags(after)
  tags["Environment"] != "prod"

  msg := sprintf("CloudWatch Log Group '%s' in non-production environment has retention set to %d days. Consider shorter retention (7-30 days) to reduce storage costs.", [
    after.name,
    retention
  ])
}

# Warn about containers without readonly root filesystem
warn contains msg if {
  resource := resource_changes_by_type("aws_ecs_task_definition")[_]
  after := resource.change.after

  # Parse container definitions JSON
  container_defs := json.unmarshal(after.container_definitions)
  container := container_defs[_]

  # Check if readonlyRootFilesystem is false or not set
  not container.readonlyRootFilesystem

  msg := sprintf("ECS Task Definition '%s' has container '%s' without readonly root filesystem. Consider enabling readonlyRootFilesystem for better security.", [
    after.family,
    container.name
  ])
}
