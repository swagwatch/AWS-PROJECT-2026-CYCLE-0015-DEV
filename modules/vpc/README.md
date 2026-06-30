# AWS VPC Terraform Module

A production-ready Terraform module for deploying AWS Virtual Private Cloud (VPC) infrastructure with integrated OPA policy validation.

## Overview

This module creates a complete VPC infrastructure following AWS and Terraform best practices. It includes public and private subnets, NAT gateways for private subnet internet access, routing configuration, and security groups with least-privilege defaults.

## Features

- **Multi-AZ VPC Deployment**: Deploy VPC resources across multiple availability zones for high availability
- **Public and Private Subnets**: Separate network tiers for different resource types
- **NAT Gateway**: Configurable NAT Gateway deployment (single or per-AZ) for private subnet internet access
- **Internet Gateway**: Automatic internet gateway creation for public subnet access
- **Route Tables**: Properly configured routing for public and private subnets
- **Security Groups**: Default security group with least-privilege rules
- **Flexible CIDR Configuration**: Customizable VPC and subnet CIDR blocks
- **Comprehensive Tagging**: Consistent resource tagging for management and cost allocation
- **OPA Policy Validation**: Built-in security and compliance validation

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0, < 6.0.0 |

## Usage

### Basic Example

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "my-vpc"
  vpc_cidr_block       = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  environment          = "dev"
  owner                = "platform-team"

  tags = {
    Project = "my-project"
  }
}
```

### Single NAT Gateway (Cost-Optimized)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "dev-vpc"
  vpc_cidr_block       = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true  # Use single NAT gateway for cost savings
  environment          = "dev"
  owner                = "dev-team"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name of the VPC | `string` | n/a | yes |
| vpc_cidr_block | CIDR block for the VPC (must be within RFC 1918 private ranges) | `string` | n/a | yes |
| availability_zones | List of availability zones to use for subnets | `list(string)` | n/a | yes |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| owner | Owner of the VPC resources | `string` | n/a | yes |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in the VPC | `bool` | `true` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Use a single NAT Gateway for all private subnets (cost optimization) | `bool` | `false` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| public_subnet_cidrs | List of CIDR blocks of public subnets |
| private_subnet_cidrs | List of CIDR blocks of private subnets |
| internet_gateway_id | The ID of the Internet Gateway |
| nat_gateway_ids | List of NAT Gateway IDs |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of IDs of private route tables |
| default_security_group_id | ID of the VPC's default security group |

## OPA Policies

This module includes OPA policies that enforce security and best practices:

### Deny Rules (Critical)
- **Required Tags**: VPC must have `Environment` and `Owner` tags
- **RFC 1918 CIDR**: VPC CIDR must be within private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- **Subnet CIDR Validation**: Subnet CIDRs must be within VPC CIDR range
- **Security Group Rules**: Default security group must not allow SSH (port 22) from 0.0.0.0/0

### Warning Rules (Best Practices)
- **Multi-AZ Deployment**: Recommends deploying across at least 2 availability zones
- **Cost Optimization**: Warns about multiple NAT Gateways and suggests single NAT gateway option
- **DNS Hostnames**: Recommends enabling DNS hostnames for VPC endpoints

## Examples

### Three Availability Zones

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "prod-vpc"
  vpc_cidr_block       = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  environment          = "prod"
  owner                = "platform-team"
}
```

### Custom CIDR Ranges (172.x)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "staging-vpc"
  vpc_cidr_block       = "172.20.0.0/16"
  availability_zones   = ["us-west-2a", "us-west-2b"]
  public_subnet_cidrs  = ["172.20.1.0/24", "172.20.2.0/24"]
  private_subnet_cidrs = ["172.20.11.0/24", "172.20.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  environment          = "staging"
  owner                = "staging-team"
}
```

## Notes

### Best Practices

- **CIDR Planning**: Choose VPC CIDR blocks carefully as they cannot be changed after VPC creation
- **Multi-AZ**: Always deploy across at least 2 availability zones for production workloads
- **NAT Gateway**: Use single NAT gateway for dev/test environments to reduce costs; use per-AZ NAT gateways for production high availability
- **Tagging**: Consistent tagging helps with cost allocation, resource management, and automation
- **Security Groups**: Modify the default security group rules based on your security requirements

### Cost Considerations

- **NAT Gateway**: Primary cost driver (~$0.045/hour + data processing charges per GB)
- **VPC, Subnets, Route Tables**: No charge
- **Elastic IPs**: No charge when attached to running NAT gateway
- **Estimated Cost**: With 2 NAT Gateways: ~$65/month + data transfer costs

### Module Design

- **Flexibility**: Module balances configurability with sensible defaults
- **Least Privilege**: Default security group follows least-privilege principles
- **Resource Naming**: Consistent naming pattern: `{vpc_name}-{environment}-{resource_type}`
- **Subnet Organization**: Public subnets for internet-facing resources, private subnets for internal resources

## License

This module is part of the terraform-vpc-module project.
