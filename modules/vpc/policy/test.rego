package terraform.aws.vpc

import rego.v1

# Test 1: Valid VPC configuration with all required tags and proper settings
test_valid_vpc_configuration if {
	result := deny with input as {
		"resource_changes": [
			{
				"type": "aws_vpc",
				"address": "aws_vpc.main",
				"change": {
					"actions": ["create"],
					"after": {
						"cidr_block": "10.0.0.0/16",
						"enable_dns_hostnames": true,
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"type": "aws_subnet",
				"address": "aws_subnet.public[0]",
				"change": {
					"actions": ["create"],
					"after": {
						"cidr_block": "10.0.1.0/24",
						"availability_zone": "us-east-1a",
					},
				},
			},
			{
				"type": "aws_subnet",
				"address": "aws_subnet.public[1]",
				"change": {
					"actions": ["create"],
					"after": {
						"cidr_block": "10.0.2.0/24",
						"availability_zone": "us-east-1b",
					},
				},
			},
		],
	}
	count(result) == 0
}

# Test 2: Invalid VPC configuration missing required tags
test_vpc_missing_environment_tag if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["create"],
				"after": {
					"cidr_block": "10.0.0.0/16",
					"tags": {"Owner": "platform-team"},
				},
			},
		}],
	}
	count(result) > 0
}

test_vpc_missing_owner_tag if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["create"],
				"after": {
					"cidr_block": "10.0.0.0/16",
					"tags": {"Environment": "dev"},
				},
			},
		}],
	}
	count(result) > 0
}

# Test 3: Invalid VPC with CIDR outside RFC 1918 ranges
test_vpc_invalid_cidr_block if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["create"],
				"after": {
					"cidr_block": "8.8.8.0/24",
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(result) > 0
}

# Test 4: Warning for single availability zone
test_vpc_single_az_warning if {
	result := warn with input as {
		"resource_changes": [
			{
				"type": "aws_vpc",
				"address": "aws_vpc.main",
				"change": {
					"actions": ["create"],
					"after": {
						"cidr_block": "10.0.0.0/16",
						"enable_dns_hostnames": true,
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"type": "aws_subnet",
				"address": "aws_subnet.public[0]",
				"change": {
					"actions": ["create"],
					"after": {
						"cidr_block": "10.0.1.0/24",
						"availability_zone": "us-east-1a",
					},
				},
			},
		],
	}
	count(result) > 0
}

# Test 5: Warning for multiple NAT Gateways
test_multiple_nat_gateways_warning if {
	result := warn with input as {
		"resource_changes": [
			{
				"type": "aws_nat_gateway",
				"address": "aws_nat_gateway.main[0]",
				"change": {
					"actions": ["create"],
					"after": {},
				},
			},
			{
				"type": "aws_nat_gateway",
				"address": "aws_nat_gateway.main[1]",
				"change": {
					"actions": ["create"],
					"after": {},
				},
			},
		],
	}
	count(result) > 0
}

# Test 6: Delete action should be ignored
test_delete_action_ignored if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["delete"],
				"after": null,
			},
		}],
	}
	count(result) == 0
}

# Test 7: Test RFC 1918 CIDR validation for 172.16.0.0/12 range
test_vpc_valid_cidr_172_range if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["create"],
				"after": {
					"cidr_block": "172.20.0.0/16",
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(result) == 0
}

# Test 8: Test RFC 1918 CIDR validation for 192.168.0.0/16 range
test_vpc_valid_cidr_192_range if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_vpc",
			"address": "aws_vpc.main",
			"change": {
				"actions": ["create"],
				"after": {
					"cidr_block": "192.168.0.0/16",
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(result) == 0
}
