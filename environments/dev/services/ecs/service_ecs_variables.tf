# Variables for ECS service

variable "vpc_id" {
  description = "VPC ID for the ECS service"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS service"
  type        = list(string)
}
