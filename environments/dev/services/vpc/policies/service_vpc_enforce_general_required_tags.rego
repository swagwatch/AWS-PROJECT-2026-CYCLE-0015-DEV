# enforce_required_tags.rego
# checks resources for required tags

package general
import data.terraform.plan_functions
import data.terraform.utility_functions
import input.resource_changes


# Required tags for all resources
required_tags := {"environment","project","owner"}


# Resources defined in this service that can be assigned tags

# aws_default_network_acl
aws_default_network_acl := plan_functions.get_resources_by_type("aws_default_network_acl", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_default_network_acl,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_default_security_group
aws_default_security_group := plan_functions.get_resources_by_type("aws_default_security_group", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_default_security_group,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_eip
aws_eip := plan_functions.get_resources_by_type("aws_eip", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_eip,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_internet_gateway
aws_internet_gateway := plan_functions.get_resources_by_type("aws_internet_gateway", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_internet_gateway,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_nat_gateway
aws_nat_gateway := plan_functions.get_resources_by_type("aws_nat_gateway", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_nat_gateway,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_network_acl
aws_network_acl := plan_functions.get_resources_by_type("aws_network_acl", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_network_acl,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_route_table
aws_route_table := plan_functions.get_resources_by_type("aws_route_table", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_route_table,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_security_group
aws_security_group := plan_functions.get_resources_by_type("aws_security_group", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_security_group,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_subnet
aws_subnet := plan_functions.get_resources_by_type("aws_subnet", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_subnet,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_vpc
aws_vpc := plan_functions.get_resources_by_type("aws_vpc", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_vpc,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

# aws_vpc_endpoint
aws_vpc_endpoint := plan_functions.get_resources_by_type("aws_vpc_endpoint", resource_changes)

deny[msg] {
    resources := utility_functions.tags_contain_required(aws_vpc_endpoint,required_tags)
    resources != []
    msg := sprintf("[GENERAL] [VPC] - The following resources are missing required tags: %s", [resources[_].address])
}

