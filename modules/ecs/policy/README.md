# ECS OPA Policy Validation

This directory contains Open Policy Agent (OPA) Rego policies that validate AWS ECS Terraform configurations against security and compliance best practices.

## Purpose

The policies automatically validate Terraform plans before deployment to ensure:
- Required tags are present on all resources
- Security groups follow least-privilege principles
- ECS tasks use appropriate network modes for their launch type
- Fargate tasks have required IAM roles
- Production logs are encrypted
- Cost optimization opportunities are identified

## Policy Structure

- **main.rego**: Contains all policy rules (DENY and WARN)
- **test.rego**: Contains comprehensive test cases for policy validation

## DENY Rules (Critical - Will Fail Pipeline)

These rules represent critical security and compliance violations that will prevent deployment:

### 1. Required Tags

**Rule**: All ECS resources must have `Environment` and `Owner` tags

**Resources Checked**:
- `aws_ecs_cluster`
- `aws_ecs_service`
- `aws_ecs_task_definition`

**Example Violation**:
```hcl
resource "aws_ecs_cluster" "this" {
  name = "my-cluster"
  # Missing tags!
}
```

**Fix**:
```hcl
resource "aws_ecs_cluster" "this" {
  name = "my-cluster"
  tags = {
    Environment = "prod"
    Owner       = "platform-team"
  }
}
```

### 2. Fargate Network Mode Requirement

**Rule**: Task definitions with FARGATE compatibility must use `awsvpc` network mode

**Rationale**: Fargate only supports awsvpc network mode

**Example Violation**:
```hcl
resource "aws_ecs_task_definition" "this" {
  family                   = "my-task"
  network_mode             = "bridge"  # Wrong!
  requires_compatibilities = ["FARGATE"]
}
```

**Fix**:
```hcl
resource "aws_ecs_task_definition" "this" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}
```

### 3. Fargate Execution Role Requirement

**Rule**: Task definitions with FARGATE compatibility must have an execution role

**Rationale**: Fargate requires an execution role to pull container images and write logs

**Example Violation**:
```hcl
resource "aws_ecs_task_definition" "this" {
  family                   = "my-task"
  requires_compatibilities = ["FARGATE"]
  # Missing execution_role_arn!
}
```

**Fix**:
```hcl
resource "aws_ecs_task_definition" "this" {
  family                   = "my-task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution.arn
}
```

### 4. Restricted Security Group Access

**Rule**: Security group ingress rules must not allow unrestricted access (0.0.0.0/0) to sensitive ports

**Sensitive Ports**: 22 (SSH), 3389 (RDP), 3306 (MySQL), 5432 (PostgreSQL), 1433 (SQL Server), 27017 (MongoDB), 6379 (Redis), 9200 (Elasticsearch)

**Example Violation**:
```hcl
resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Overly permissive!
}
```

**Fix**:
```hcl
resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]  # Restrict to VPC
}
```

### 5. Production Log Encryption

**Rule**: CloudWatch log groups in production environments must have KMS encryption enabled

**Example Violation**:
```hcl
resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/prod/app"
  tags = {
    Environment = "prod"
    Owner       = "team"
  }
  # Missing kms_key_id!
}
```

**Fix**:
```hcl
resource "aws_cloudwatch_log_group" "this" {
  name       = "/ecs/prod/app"
  kms_key_id = aws_kms_key.logs.id
  tags = {
    Environment = "prod"
    Owner       = "team"
  }
}
```

### 6. Public IP Documentation

**Rule**: ECS services that assign public IPs must have a `PublicAccess` tag documenting the decision

**Rationale**: Public IPs should be intentional and documented for security auditing

**Example Violation**:
```hcl
resource "aws_ecs_service" "this" {
  name = "my-service"
  network_configuration {
    assign_public_ip = true
  }
  tags = {
    Environment = "dev"
    Owner       = "team"
    # Missing PublicAccess tag!
  }
}
```

**Fix**:
```hcl
resource "aws_ecs_service" "this" {
  name = "my-service"
  network_configuration {
    assign_public_ip = true
  }
  tags = {
    Environment = "dev"
    Owner       = "team"
    PublicAccess = "true"  # Document the decision
  }
}
```

## WARN Rules (Best Practices - Non-Blocking)

These rules identify cost optimization opportunities and best practices but do not prevent deployment:

### 1. FARGATE_SPOT Recommendation

**Rule**: Non-production Fargate services should consider using FARGATE_SPOT for cost savings

**Savings**: Up to 70% cost reduction compared to standard Fargate

**Current**: Standard FARGATE launch type in dev/staging

**Recommendation**: Use capacity provider strategy with FARGATE_SPOT

### 2. High CPU Allocation

**Rule**: Task definitions with 4096+ CPU units (4+ vCPUs) should verify resource necessity

**Rationale**: Over-provisioned resources increase costs unnecessarily

### 3. High Memory Allocation

**Rule**: Task definitions with 16384+ MiB memory (16+ GB) should verify resource necessity

**Rationale**: Over-provisioned memory increases costs unnecessarily

### 4. Container Insights Disabled

**Rule**: ECS clusters should have Container Insights enabled for better observability

**Benefits**:
- Detailed performance metrics
- Automated CloudWatch dashboards
- Better troubleshooting capabilities

### 5. Long Log Retention

**Rule**: Non-production logs with retention > 30 days should consider shorter retention

**Rationale**: Log storage costs accumulate over time

**Recommendation**: Use 7-30 days retention for dev/staging environments

### 6. Readonly Root Filesystem

**Rule**: Containers should enable `readonlyRootFilesystem` when possible

**Security Benefit**: Prevents runtime modifications to container filesystem

## Testing Policies Locally

### Check Policy Syntax

```bash
opa check modules/ecs/policy/main.rego modules/ecs/policy/test.rego
```

### Run Policy Tests

```bash
opa test modules/ecs/policy/ -v
```

Expected output:
```
modules/ecs/policy/test.rego:
data.terraform.aws.ecs.test_valid_configuration_no_violations: PASS (0.5ms)
data.terraform.aws.ecs.test_invalid_configuration_with_violations: PASS (0.7ms)
data.terraform.aws.ecs.test_invalid_configuration_has_missing_tags_violation: PASS (0.6ms)
data.terraform.aws.ecs.test_invalid_configuration_has_network_mode_violation: PASS (0.5ms)
data.terraform.aws.ecs.test_invalid_configuration_has_execution_role_violation: PASS (0.5ms)
data.terraform.aws.ecs.test_invalid_configuration_has_security_group_violation: PASS (0.6ms)
data.terraform.aws.ecs.test_delete_action_ignored: PASS (0.3ms)
--------------------------------------------------------------------------------
PASS: 7/7
```

### Validate Against Terraform Plan

```bash
# Generate Terraform plan
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run OPA evaluation
opa eval -d opa-policies/service_ecs_policies.rego \
  -i tfplan.json \
  --fail "count(data.terraform.aws.ecs.deny) > 0"
```

If violations exist:
```bash
# View violations
opa eval -i tfplan.json \
  -d opa-policies/service_ecs_policies.rego \
  "data.terraform.aws.ecs.deny"
```

## Test Coverage

The test suite includes:

1. **Valid Configuration Test**: Verifies compliant configurations pass all checks
   - All required tags present
   - Correct network mode for Fargate
   - Proper IAM roles configured
   - Appropriate security group rules

2. **Invalid Configuration Test**: Verifies violations are detected
   - Missing required tags
   - Wrong network mode for Fargate
   - Missing execution role
   - Overly permissive security groups
   - Missing production log encryption

3. **Delete Action Test**: Verifies resources being deleted don't trigger violations
   - Delete actions are excluded from validation
   - Helper function correctly filters by action type

## Integration with CI/CD

These policies are automatically enforced in:

1. **Pre-commit Hook**: Validates before allowing commits
2. **GitHub Actions**: Validates on pull requests
3. **Pipeline**: Validates before Terraform apply

## Extending Policies

To add new rules:

1. Add rule to `main.rego` in either `deny` or `warn` section
2. Add test case to `test.rego`
3. Run `opa test` to verify
4. Update this README with rule documentation

## Policy Maintenance

- Review policies quarterly for new AWS best practices
- Update sensitive ports list as needed
- Adjust resource thresholds based on workload patterns
- Add new rules for emerging security requirements

## Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-reference/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
