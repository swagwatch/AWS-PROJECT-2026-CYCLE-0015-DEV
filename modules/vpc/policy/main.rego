package terraform.aws.vpc

# Evaluate Terraform plan JSON (terraform show -json plan.tfplan)
# Provides:
# - deny: CRITICAL violations that must fail the pipeline
# - warn: non-blocking warnings
# - info: informational findings

# Helper: return resource changes for a given type that are created or updated
resource_changes_by_type(res_type) := array.concat(creates, updates) if {
  creates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "create")
  ]
  updates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "update")
  ]
}

# Helper: get tags from after object
get_tags(after) = tags_out if {
  tags := after.tags
  tags_out := tags
} else = tags_all_out if {
  tags_all := after.tags_all
  tags_all_out := tags_all
} else = {} if {
  true
}

# Helper: check if a list contains a value
array_contains(arr, v) if {
  some i
  arr[i] == v
}

# ------------------------
# DENY Rules (Security Best Practices - CRITICAL)
# ------------------------

# Deny: VPC must have required tags (Environment and Owner)
deny contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  tags := get_tags(vpc.change.after)
  not tags.Environment
  msg := sprintf("VPC '%s' is missing required tag 'Environment'", [vpc.address])
}

deny contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  tags := get_tags(vpc.change.after)
  not tags.Owner
  msg := sprintf("VPC '%s' is missing required tag 'Owner'", [vpc.address])
}

# Deny: VPC CIDR must be within RFC 1918 private ranges
deny contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  cidr := vpc.change.after.cidr_block
  not is_rfc1918_cidr(cidr)
  msg := sprintf("VPC '%s' CIDR block '%s' is not within RFC 1918 private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)", [vpc.address, cidr])
}

# Helper: Check if CIDR is within RFC 1918 private ranges
is_rfc1918_cidr(cidr) if {
  startswith(cidr, "10.")
}

is_rfc1918_cidr(cidr) if {
  startswith(cidr, "172.")
  parts := split(cidr, ".")
  second_octet := to_number(parts[1])
  second_octet >= 16
  second_octet <= 31
}

is_rfc1918_cidr(cidr) if {
  startswith(cidr, "192.168.")
}

# Deny: Subnet CIDR must be within VPC CIDR range
deny contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  vpc_cidr := vpc.change.after.cidr_block
  subnet := resource_changes_by_type("aws_subnet")[_]
  subnet_cidr := subnet.change.after.cidr_block
  not cidr_contains(vpc_cidr, subnet_cidr)
  msg := sprintf("Subnet '%s' CIDR '%s' is not within VPC CIDR '%s'", [subnet.address, subnet_cidr, vpc_cidr])
}

# Helper: Check if cidr1 contains cidr2 (simplified check for basic validation)
cidr_contains(vpc_cidr, subnet_cidr) if {
  vpc_prefix := split(vpc_cidr, "/")[0]
  subnet_prefix := split(subnet_cidr, "/")[0]
  vpc_parts := split(vpc_prefix, ".")
  subnet_parts := split(subnet_prefix, ".")
  startswith(subnet_cidr, split(vpc_cidr, "/")[0])
}

cidr_contains(vpc_cidr, subnet_cidr) if {
  vpc_prefix := split(vpc_cidr, "/")[0]
  subnet_prefix := split(subnet_cidr, "/")[0]
  vpc_first_octet := split(vpc_prefix, ".")[0]
  subnet_first_octet := split(subnet_prefix, ".")[0]
  vpc_first_octet == subnet_first_octet
  vpc_second_octet := split(vpc_prefix, ".")[1]
  subnet_second_octet := split(subnet_prefix, ".")[1]
  vpc_second_octet == subnet_second_octet
}

# Deny: Default security group must not allow SSH from 0.0.0.0/0
deny contains msg if {
  sg := resource_changes_by_type("aws_default_security_group")[_]
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  cidr := ingress.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := sprintf("Default security group '%s' allows SSH (port 22) from 0.0.0.0/0. This is a security risk.", [sg.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# Warn: VPC should span multiple availability zones for high availability
warn contains msg if {
  subnets := resource_changes_by_type("aws_subnet")
  count(subnets) > 0
  azs := {subnet.change.after.availability_zone | subnet := subnets[_]}
  count(azs) < 2
  msg := "VPC spans fewer than 2 availability zones. Consider deploying across multiple AZs for high availability."
}

# Warn: Multiple NAT Gateways increase costs
warn contains msg if {
  nat_gateways := resource_changes_by_type("aws_nat_gateway")
  count(nat_gateways) > 1
  msg := sprintf("Deploying %d NAT Gateways. Consider using a single NAT Gateway (single_nat_gateway=true) to reduce costs if high availability is not critical.", [count(nat_gateways)])
}

# Warn: Recommend enabling DNS hostnames for VPC endpoints
warn contains msg if {
  vpc := resource_changes_by_type("aws_vpc")[_]
  not vpc.change.after.enable_dns_hostnames
  msg := sprintf("VPC '%s' does not have DNS hostnames enabled. This is recommended for VPC endpoints and service discovery.", [vpc.address])
}
