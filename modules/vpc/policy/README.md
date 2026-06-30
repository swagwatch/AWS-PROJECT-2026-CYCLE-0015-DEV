# VPC OPA Policy Documentation

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS VPC Terraform configurations. These policies enforce security, compliance, and cost optimization best practices.

## Overview

The OPA policies analyze Terraform plan JSON output and provide two types of feedback:

- **Deny Rules**: CRITICAL violations that must be fixed before deployment. These will fail the pipeline.
- **Warn Rules**: Non-blocking recommendations for best practices and cost optimization.

## Policy Rules

### Deny Rules (Critical Violations)

These rules enforce security and compliance requirements. Any violation will block deployment.

#### 1. Required Tags - Environment

**Rule**: VPC must have an `Environment` tag

**Why**: The Environment tag is essential for:
- Cost allocation and tracking across environments
- Resource organization and filtering
- Compliance with organizational tagging policies
- Automated management and lifecycle policies

**How to Fix**:
```hcl
module "vpc" {
  # ... other configuration ...
  environment = "dev"  # or "staging", "prod", etc.
}
```

**Error Message**: `VPC 'aws_vpc.main' is missing required tag 'Environment'`

#### 2. Required Tags - Owner

**Rule**: VPC must have an `Owner` tag

**Why**: The Owner tag is critical for:
- Accountability and responsibility tracking
- Cost attribution to teams or projects
- Contact information for resource issues
- Security and compliance auditing

**How to Fix**:
```hcl
module "vpc" {
  # ... other configuration ...
  owner = "platform-team"  # team or individual responsible
}
```

**Error Message**: `VPC 'aws_vpc.main' is missing required tag 'Owner'`

#### 3. RFC 1918 Private CIDR Ranges

**Rule**: VPC CIDR block must be within RFC 1918 private address ranges

**Why**: Using public IP ranges for VPCs can cause:
- Routing conflicts with public internet
- Security vulnerabilities
- Connectivity issues with AWS services
- Violation of networking best practices

**Allowed CIDR Ranges**:
- `10.0.0.0/8` (10.0.0.0 - 10.255.255.255)
- `172.16.0.0/12` (172.16.0.0 - 172.31.255.255)
- `192.168.0.0/16` (192.168.0.0 - 192.168.255.255)

**How to Fix**:
```hcl
module "vpc" {
  vpc_cidr_block = "10.0.0.0/16"  # Use RFC 1918 private range
  # NOT: vpc_cidr_block = "8.8.8.0/24"  # Public IP range - INVALID
}
```

**Error Message**: `VPC 'aws_vpc.main' CIDR block '8.8.8.0/24' is not within RFC 1918 private ranges`

#### 4. Subnet CIDR Within VPC CIDR

**Rule**: All subnet CIDR blocks must be within the VPC CIDR range

**Why**: Subnet CIDRs outside the VPC CIDR will:
- Fail during terraform apply
- Cause routing issues
- Prevent resource creation
- Violate AWS VPC networking model

**How to Fix**:
```hcl
module "vpc" {
  vpc_cidr_block      = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]  # Within 10.0.0.0/16
  # NOT: ["192.168.1.0/24"]  # Outside VPC CIDR - INVALID
}
```

**Error Message**: `Subnet 'aws_subnet.public[0]' CIDR '192.168.1.0/24' is not within VPC CIDR '10.0.0.0/16'`

#### 5. No SSH from Internet

**Rule**: Default security group must not allow SSH (port 22) from 0.0.0.0/0

**Why**: Allowing SSH from the internet is a critical security risk:
- Exposes resources to brute force attacks
- Increases attack surface
- Violates security best practices
- May fail compliance audits (PCI-DSS, HIPAA, etc.)

**How to Fix**:
The module's default security group is already configured with least-privilege rules. This deny rule prevents accidental misconfigurations.

**Error Message**: `Default security group 'aws_default_security_group.default' allows SSH (port 22) from 0.0.0.0/0. This is a security risk.`

### Warn Rules (Best Practice Recommendations)

These rules provide guidance but don't block deployment.

#### 1. Multi-AZ Deployment

**Recommendation**: VPC should span at least 2 availability zones

**Why**: Single-AZ deployments have risks:
- No redundancy if AZ experiences outage
- Reduced high availability
- Not suitable for production workloads
- Limits disaster recovery capabilities

**How to Implement**:
```hcl
module "vpc" {
  availability_zones   = ["us-east-1a", "us-east-1b"]  # At least 2 AZs
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

**Warning Message**: `VPC spans fewer than 2 availability zones. Consider deploying across multiple AZs for high availability.`

#### 2. Multiple NAT Gateways Cost Warning

**Recommendation**: Consider using single NAT gateway for cost optimization in non-production environments

**Why**: Multiple NAT Gateways:
- Cost ~$0.045/hour per NAT Gateway
- Approximately $65/month for 2 NAT Gateways
- May not be necessary for dev/test environments
- Trade-off between cost and high availability

**How to Optimize**:
```hcl
# For dev/test environments
module "vpc" {
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost-optimized
}

# For production environments
module "vpc" {
  enable_nat_gateway = true
  single_nat_gateway = false  # High availability
}
```

**Warning Message**: `Deploying N NAT Gateways. Consider using a single NAT Gateway (single_nat_gateway=true) to reduce costs if high availability is not critical.`

#### 3. DNS Hostnames Recommendation

**Recommendation**: Enable DNS hostnames for VPC endpoints and service discovery

**Why**: DNS hostnames enable:
- VPC endpoints for AWS services (S3, DynamoDB, etc.)
- Service discovery within the VPC
- Better integration with AWS services
- Simplified resource access

**How to Enable**:
```hcl
module "vpc" {
  enable_dns_hostnames = true  # Recommended (default)
}
```

**Warning Message**: `VPC 'aws_vpc.main' does not have DNS hostnames enabled. This is recommended for VPC endpoints and service discovery.`

## Running Tests

### Validate Policy Syntax

```bash
opa check modules/vpc/policy/main.rego modules/vpc/policy/test.rego
```

### Run Policy Unit Tests

```bash
opa test modules/vpc/policy/ -v
```

Expected output:
```
PASS: 9/9
```

### Test Against Terraform Plan

```bash
# Generate Terraform plan
cd environments/dev
terraform plan -out=tfplan.binary

# Convert to JSON
terraform show -json tfplan.binary > tfplan.json

# Run OPA validation
opa eval -d opa-policies/service_vpc_policies.rego -i tfplan.json --fail "count(data.terraform.aws.vpc.deny) > 0"
```

Exit code 0 means no critical violations. Non-zero exit code indicates deny rules were triggered.

## Integration with CI/CD

These policies are automatically enforced via:

1. **Pre-commit Hooks**: Local validation before commit
2. **CI Pipeline**: Automated validation on pull requests
3. **Deployment Pipeline**: Final validation before deployment

## Customizing Policies

To add custom policies:

1. Add new deny or warn rules to `main.rego`
2. Add corresponding test cases to `test.rego`
3. Run `opa test` to verify tests pass
4. Document the new rules in this README

### Example: Adding a Custom Rule

```rego
# Deny: VPC must have a specific tag
deny contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  tags := get_tags(vpc.change.after)
  not tags.CostCenter
  msg := sprintf("VPC '%s' is missing required tag 'CostCenter'", [vpc.address])
}
```

## Helper Functions

The policy includes reusable helper functions:

- `resource_changes_by_type(type)`: Get resources of a specific type being created/updated
- `get_tags(after)`: Extract tags from resource configuration
- `array_contains(array, value)`: Check if array contains a value
- `is_rfc1918_cidr(cidr)`: Validate if CIDR is in RFC 1918 range
- `cidr_contains(vpc_cidr, subnet_cidr)`: Check if subnet CIDR is within VPC CIDR

## Troubleshooting

### Policy Validation Fails

1. Review the error message to identify which rule failed
2. Check this README for the specific rule documentation
3. Update your Terraform configuration to comply with the rule
4. Re-run validation

### Tests Don't Pass

1. Run `opa test modules/vpc/policy/ -v` for detailed output
2. Check test definitions in `test.rego`
3. Verify policy logic in `main.rego`
4. Ensure test data matches expected format

### False Positives

If a policy rule incorrectly flags valid configurations:
1. Review the rule logic in `main.rego`
2. Add edge case handling if needed
3. Update tests to cover the edge case

## Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-reference/)
- [Terraform Plan JSON Format](https://www.terraform.io/docs/internals/json-format.html)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
