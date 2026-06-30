# =====================================================
# ECS Cluster Configuration
# =====================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

# =====================================================
# ECS Service Configuration
# =====================================================

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks to run in the service"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be greater than or equal to 0."
  }
}

variable "launch_type" {
  description = "Launch type for the service (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Launch type must be either FARGATE or EC2."
  }
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's desired_count) of the number of running tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's desired_count) of the number of running tasks during deployment"
  type        = number
  default     = 100
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# =====================================================
# Task Definition Configuration
# =====================================================

variable "task_family" {
  description = "Family name for the task definition"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MiB (512, 1024, 2048, etc.)"
  type        = string
  default     = "512"
}

variable "network_mode" {
  description = "Network mode for the task definition (awsvpc, bridge, host, none)"
  type        = string
  default     = "awsvpc"

  validation {
    condition     = contains(["awsvpc", "bridge", "host", "none"], var.network_mode)
    error_message = "Network mode must be one of: awsvpc, bridge, host, none."
  }
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task (FARGATE, EC2)"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "container_definitions" {
  description = "Container definitions for the task"
  type = list(object({
    name      = string
    image     = string
    cpu       = optional(number)
    memory    = optional(number)
    essential = optional(bool, true)
    portMappings = optional(list(object({
      containerPort = number
      hostPort      = optional(number)
      protocol      = optional(string, "tcp")
    })), [])
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    readonlyRootFilesystem = optional(bool, false)
  }))
}

# =====================================================
# Networking Configuration
# =====================================================

variable "vpc_id" {
  description = "VPC ID where the ECS service will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string), [])
    description = optional(string)
  }))
  default = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }]
}

# =====================================================
# Load Balancer Configuration
# =====================================================

variable "enable_load_balancer" {
  description = "Enable load balancer integration"
  type        = bool
  default     = false
}

variable "target_group_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
}

variable "deregistration_delay" {
  description = "Time in seconds for load balancer to wait before deregistering target"
  type        = number
  default     = 30
}

variable "container_name" {
  description = "Name of the container to associate with the load balancer"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port on the container to associate with the load balancer"
  type        = number
  default     = 80
}

# =====================================================
# Logging Configuration
# =====================================================

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_log_encryption" {
  description = "Enable encryption for CloudWatch logs"
  type        = bool
  default     = false
}

variable "log_kms_key_id" {
  description = "KMS key ID for CloudWatch log encryption"
  type        = string
  default     = null
}

# =====================================================
# IAM Configuration
# =====================================================

variable "create_task_execution_role" {
  description = "Create a new task execution role"
  type        = bool
  default     = true
}

variable "task_execution_role_arn" {
  description = "ARN of an existing task execution role (if create_task_execution_role is false)"
  type        = string
  default     = null
}

variable "task_execution_role_policies" {
  description = "Additional IAM policy ARNs to attach to the task execution role"
  type        = list(string)
  default     = []
}

variable "create_task_role" {
  description = "Create a new task role"
  type        = bool
  default     = true
}

variable "task_role_arn" {
  description = "ARN of an existing task role (if create_task_role is false)"
  type        = string
  default     = null
}

variable "task_role_policies" {
  description = "Additional IAM policy ARNs to attach to the task role"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policy" {
  description = "Inline policy JSON to attach to the task role"
  type        = string
  default     = null
}

# =====================================================
# Service Discovery Configuration
# =====================================================

variable "enable_service_discovery" {
  description = "Enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "ID of the Cloud Map namespace for service discovery"
  type        = string
  default     = null
}

variable "service_discovery_dns_ttl" {
  description = "TTL for service discovery DNS records"
  type        = number
  default     = 10
}

# =====================================================
# Tagging
# =====================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags for the ECS cluster"
  type        = map(string)
  default     = {}
}

variable "service_tags" {
  description = "Additional tags for the ECS service"
  type        = map(string)
  default     = {}
}

variable "task_definition_tags" {
  description = "Additional tags for the task definition"
  type        = map(string)
  default     = {}
}
