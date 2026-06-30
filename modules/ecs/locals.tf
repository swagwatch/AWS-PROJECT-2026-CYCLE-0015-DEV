locals {
  # Resource naming
  cluster_name        = var.cluster_name
  service_name        = var.service_name
  task_family         = var.task_family
  log_group_name      = "/ecs/${var.cluster_name}/${var.task_family}"
  security_group_name = "${var.service_name}-sg"
  target_group_name   = "${var.service_name}-tg"

  # Task execution role
  task_execution_role_arn = var.create_task_execution_role ? aws_iam_role.task_execution[0].arn : var.task_execution_role_arn

  # Task role
  task_role_arn = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn

  # Container definitions with logging configuration
  container_definitions_json = jsonencode([
    for container in var.container_definitions : merge(
      {
        name                   = container.name
        image                  = container.image
        essential              = container.essential
        portMappings           = container.portMappings
        environment            = container.environment
        secrets                = container.secrets
        readonlyRootFilesystem = container.readonlyRootFilesystem
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = local.log_group_name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }
      },
      container.cpu != null ? { cpu = container.cpu } : {},
      container.memory != null ? { memory = container.memory } : {}
    )
  ])

  # Merged tags
  cluster_tags = merge(
    var.common_tags,
    var.cluster_tags,
    {
      Name = local.cluster_name
    }
  )

  service_tags = merge(
    var.common_tags,
    var.service_tags,
    {
      Name = local.service_name
    }
  )

  task_definition_tags = merge(
    var.common_tags,
    var.task_definition_tags,
    {
      Name = local.task_family
    }
  )

  log_group_tags = merge(
    var.common_tags,
    {
      Name = local.log_group_name
    }
  )

  security_group_tags = merge(
    var.common_tags,
    {
      Name = local.security_group_name
    }
  )

  target_group_tags = merge(
    var.common_tags,
    {
      Name = local.target_group_name
    }
  )

  # IAM role tags
  iam_role_tags = var.common_tags
}
