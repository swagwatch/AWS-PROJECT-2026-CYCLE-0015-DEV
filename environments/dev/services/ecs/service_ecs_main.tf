# ECS Module Implementation

module "ecs" {
  source = "../../modules/ecs"

  # Cluster configuration
  cluster_name              = "${local.environment}-${local.service_name}-cluster"
  enable_container_insights = true

  # Service configuration
  service_name                       = "${local.environment}-${local.service_name}-service"
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_execute_command             = false

  # Task definition configuration
  task_family              = "${local.environment}-${local.service_name}-task"
  task_cpu                 = "256"
  task_memory              = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = [
    {
      name      = "app"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = local.environment
        }
      ]
      readonlyRootFilesystem = false
    }
  ]

  # Networking configuration
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  assign_public_ip = false

  security_group_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Allow HTTP from VPC"
    }
  ]

  security_group_egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]

  # Load balancer configuration
  enable_load_balancer = false

  # Logging configuration
  log_retention_days    = 7
  enable_log_encryption = false

  # IAM configuration
  create_task_execution_role = true
  create_task_role           = true

  # Service discovery configuration
  enable_service_discovery = false

  # Tagging
  common_tags = local.common_tags
}
