# Outputs from ECS module

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "service_id" {
  description = "ID of the ECS service"
  value       = module.ecs.service_id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.ecs.security_group_id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs.log_group_name
}
