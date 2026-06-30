# AWS ECS Terraform Module

This Terraform module creates and manages AWS ECS (Elastic Container Service) infrastructure including clusters, services, task definitions, and supporting resources.

## Features

- **ECS Cluster Management**: Create and configure ECS clusters with Container Insights support
- **Fargate and EC2 Support**: Deploy containerized applications using either AWS Fargate (serverless) or EC2 launch types
- **Task Definitions**: Define container specifications including CPU, memory, environment variables, and secrets
- **Service Management**: Configure ECS services with desired count, deployment strategies, and health checks
- **Load Balancer Integration**: Optional ALB/NLB target group integration for service exposure
- **Service Discovery**: Optional AWS Cloud Map integration for service-to-service communication
- **Security Groups**: Automated security group creation with customizable ingress/egress rules
- **IAM Roles**: Automatic creation of task execution and task IAM roles with least-privilege permissions
- **CloudWatch Logging**: Centralized container logging with configurable retention periods
- **Encryption Support**: Optional KMS encryption for CloudWatch logs
- **ECS Exec Support**: Optional debugging capability via ECS Exec
- **Comprehensive Tagging**: Flexible tagging strategy for all resources

## Usage

### Basic Fargate Service

```hcl
module "ecs" {
  source = "../../modules/ecs"

  # Cluster configuration
  cluster_name              = "my-cluster"
  enable_container_insights = true

  # Service configuration
  service_name   = "my-service"
  desired_count  = 2
  launch_type    = "FARGATE"

  # Task definition
  task_family              = "my-app"
  task_cpu                 = "512"
  task_memory              = "1024"
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
      readonlyRootFilesystem = false
    }
  ]

  # Networking
  vpc_id     = "vpc-xxx"
  subnet_ids = ["subnet-xxx", "subnet-yyy"]

  security_group_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Allow HTTP from VPC"
    }
  ]

  # Logging
  log_retention_days = 7

  # Tagging
  common_tags = {
    Environment = "dev"
    Owner       = "platform-team"
  }
}
```

### With Load Balancer

```hcl
module "ecs" {
  source = "../../modules/ecs"

  # ... basic configuration ...

  # Load balancer integration
  enable_load_balancer = true
  container_name       = "app"
  container_port       = 80
  target_group_port    = 80
  target_group_protocol = "HTTP"
  health_check_path    = "/health"
}
```

### With Service Discovery

```hcl
module "ecs" {
  source = "../../modules/ecs"

  # ... basic configuration ...

  # Service discovery
  enable_service_discovery       = true
  service_discovery_namespace_id = "ns-xxx"
  service_discovery_dns_ttl      = 10
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

### Cluster Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| enable_container_insights | Enable CloudWatch Container Insights | `bool` | `true` | no |

### Service Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| service_name | Name of the ECS service | `string` | n/a | yes |
| desired_count | Desired number of tasks | `number` | `1` | no |
| launch_type | Launch type (FARGATE or EC2) | `string` | `"FARGATE"` | no |
| deployment_maximum_percent | Maximum deployment percentage | `number` | `200` | no |
| deployment_minimum_healthy_percent | Minimum healthy percentage | `number` | `100` | no |
| enable_execute_command | Enable ECS Exec | `bool` | `false` | no |

### Task Definition Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| task_family | Task definition family name | `string` | n/a | yes |
| task_cpu | CPU units for the task | `string` | `"256"` | no |
| task_memory | Memory for the task in MiB | `string` | `"512"` | no |
| network_mode | Network mode | `string` | `"awsvpc"` | no |
| requires_compatibilities | Required launch types | `list(string)` | `["FARGATE"]` | no |
| container_definitions | Container definitions | `list(object)` | n/a | yes |

### Networking Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | Subnet IDs | `list(string)` | n/a | yes |
| assign_public_ip | Assign public IP | `bool` | `false` | no |
| security_group_ingress_rules | Ingress rules | `list(object)` | `[]` | no |
| security_group_egress_rules | Egress rules | `list(object)` | See variables.tf | no |

### Load Balancer Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_load_balancer | Enable load balancer | `bool` | `false` | no |
| target_group_port | Target group port | `number` | `80` | no |
| health_check_path | Health check path | `string` | `"/"` | no |
| container_name | Container name for LB | `string` | `""` | no |
| container_port | Container port for LB | `number` | `80` | no |

### Logging Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| log_retention_days | Log retention in days | `number` | `7` | no |
| enable_log_encryption | Enable log encryption | `bool` | `false` | no |
| log_kms_key_id | KMS key ID for logs | `string` | `null` | no |

### IAM Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_task_execution_role | Create execution role | `bool` | `true` | no |
| task_execution_role_arn | Existing execution role ARN | `string` | `null` | no |
| create_task_role | Create task role | `bool` | `true` | no |
| task_role_arn | Existing task role ARN | `string` | `null` | no |
| task_role_inline_policy | Inline policy JSON | `string` | `null` | no |

### Tagging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |
| cluster_tags | Additional cluster tags | `map(string)` | `{}` | no |
| service_tags | Additional service tags | `map(string)` | `{}` | no |
| task_definition_tags | Additional task definition tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| service_id | ID of the ECS service |
| service_name | Name of the ECS service |
| service_arn | ARN of the ECS service |
| task_definition_arn | ARN of the task definition |
| task_definition_family | Family of the task definition |
| task_definition_revision | Revision of the task definition |
| security_group_id | ID of the security group |
| security_group_arn | ARN of the security group |
| task_execution_role_arn | ARN of the task execution role |
| task_role_arn | ARN of the task role |
| log_group_name | Name of the CloudWatch log group |
| log_group_arn | ARN of the CloudWatch log group |
| target_group_arn | ARN of the target group (if enabled) |
| service_discovery_arn | ARN of service discovery (if enabled) |

## Prerequisites

- VPC with subnets configured
- For load balancer integration: ALB/NLB already created
- For service discovery: Cloud Map namespace created
- For log encryption: KMS key created

## Security Considerations

- IAM roles follow least-privilege principles
- Security groups should restrict access to known sources
- Consider enabling `readonlyRootFilesystem` for containers
- Use secrets management (AWS Secrets Manager/Parameter Store) for sensitive data
- Enable encryption for production CloudWatch logs
- Avoid assigning public IPs unless necessary

## Cost Optimization

- Use FARGATE_SPOT for non-production workloads
- Right-size CPU and memory allocations
- Configure appropriate log retention periods
- Use auto-scaling for variable workloads

## Troubleshooting

### Service fails to start

- Check security group rules allow necessary traffic
- Verify subnet has internet access (NAT gateway for private subnets)
- Check IAM roles have required permissions
- Review CloudWatch logs for container errors

### Health checks failing

- Verify health check path returns 2xx status code
- Check health check timeout and interval settings
- Ensure container is listening on correct port

### Cannot pull container image

- Verify task execution role has ECR permissions
- Check image URI is correct
- Ensure ECR repository policy allows access

## License

This module is part of the internal Terraform module library.
