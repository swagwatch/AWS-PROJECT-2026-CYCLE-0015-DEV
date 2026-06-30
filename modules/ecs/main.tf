# =====================================================
# Data Sources
# =====================================================

data "aws_region" "current" {}

# =====================================================
# ECS Cluster
# =====================================================

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.cluster_tags
}

# =====================================================
# CloudWatch Log Group
# =====================================================

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.log_kms_key_id : null

  tags = local.log_group_tags
}

# =====================================================
# IAM Role - Task Execution Role
# =====================================================

resource "aws_iam_role" "task_execution" {
  count = var.create_task_execution_role ? 1 : 0

  name = "${var.task_family}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.iam_role_tags
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  count = var.create_task_execution_role ? 1 : 0

  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_additional" {
  for_each = var.create_task_execution_role ? toset(var.task_execution_role_policies) : []

  role       = aws_iam_role.task_execution[0].name
  policy_arn = each.value
}

# =====================================================
# IAM Role - Task Role
# =====================================================

resource "aws_iam_role" "task" {
  count = var.create_task_role ? 1 : 0

  name = "${var.task_family}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.iam_role_tags
}

resource "aws_iam_role_policy_attachment" "task_additional" {
  for_each = var.create_task_role ? toset(var.task_role_policies) : []

  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.create_task_role && var.task_role_inline_policy != null ? 1 : 0

  name   = "${var.task_family}-inline-policy"
  role   = aws_iam_role.task[0].id
  policy = var.task_role_inline_policy
}

# =====================================================
# Security Group
# =====================================================

resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Security group for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  tags = local.security_group_tags
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.security_group_ingress_rules : idx => rule }

  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  description              = each.value.description
  security_group_id        = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.security_group_egress_rules : idx => rule }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.this.id
}

# =====================================================
# ECS Task Definition
# =====================================================

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_family
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = local.task_execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = local.container_definitions_json

  tags = local.task_definition_tags
}

# =====================================================
# Load Balancer Target Group
# =====================================================

resource "aws_lb_target_group" "this" {
  count = var.enable_load_balancer ? 1 : 0

  name        = local.target_group_name
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = "200-299"
  }

  deregistration_delay = var.deregistration_delay

  tags = local.target_group_tags
}

# =====================================================
# Service Discovery
# =====================================================

resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery ? 1 : 0

  name = var.service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = var.service_discovery_dns_ttl
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# =====================================================
# ECS Service
# =====================================================

resource "aws_ecs_service" "this" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.container_name != "" ? var.container_name : var.container_definitions[0].name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  tags = local.service_tags

  depends_on = [
    aws_iam_role_policy_attachment.task_execution_policy,
    aws_cloudwatch_log_group.this
  ]
}
