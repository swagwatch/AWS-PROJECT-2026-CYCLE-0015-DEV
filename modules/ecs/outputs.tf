# =====================================================
# ECS Cluster Outputs
# =====================================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

# =====================================================
# ECS Service Outputs
# =====================================================

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.id
}

# =====================================================
# Task Definition Outputs
# =====================================================

output "task_definition_arn" {
  description = "ARN of the task definition (including revision)"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.this.revision
}

# =====================================================
# Security Group Outputs
# =====================================================

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.this.arn
}

# =====================================================
# IAM Role Outputs
# =====================================================

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = local.task_execution_role_arn
}

output "task_execution_role_name" {
  description = "Name of the task execution role"
  value       = var.create_task_execution_role ? aws_iam_role.task_execution[0].name : null
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = local.task_role_arn
}

output "task_role_name" {
  description = "Name of the task role"
  value       = var.create_task_role ? aws_iam_role.task[0].name : null
}

# =====================================================
# CloudWatch Log Group Outputs
# =====================================================

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

# =====================================================
# Load Balancer Target Group Outputs
# =====================================================

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.this[0].arn : null
}

output "target_group_name" {
  description = "Name of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.this[0].name : null
}

# =====================================================
# Service Discovery Outputs
# =====================================================

output "service_discovery_arn" {
  description = "ARN of the service discovery service"
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].arn : null
}

output "service_discovery_id" {
  description = "ID of the service discovery service"
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].id : null
}
