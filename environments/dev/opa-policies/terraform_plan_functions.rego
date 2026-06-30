# terraform_plan_functions.rego
# Provides functions which parse resources from a terraform plan

package terraform.plan_functions

# Keywords [  ]
import future.keywords


# Get resources by type
get_resources_by_type(type, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type]
}

# Get resources by action
get_resources_by_action(action, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.change.actions[_] = action]
}

# Get resources by type and action
get_resources_by_type_and_action(type, action, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type; resource.change.actions[_] = action]
}

# Get resource by name
get_resource_by_name(resource_name, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.name = resource_name]
}

# Get resource by type and name
get_resource_by_type_and_name(type, resource_name, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type; resource.name = resource_name]
}

# Get resource by type and name and action
get_resource_by_type_and_name_and_action(type, resource_name, action, resources) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type; resource.name = resource_name; resource.change.actions[_] = action]
}



# MATCHING NACL RULES 
get_matching_nacl_rule(resources, rule_config) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.change.after.cidr_block = rule_config.host_network; resource.change.after.egress = rule_config.egress; resource.change.after.from_port = rule_config.from_port; resource.change.after.to_port = rule_config.to_port; resource.change.after.protocol = rule_config.protocol; resource.change.after.rule_action = rule_config.rule_action]
}

# MATCHING SECURITY GROUP RULES 
get_matching_security_group_rule(resources, rule_config) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.change.after.cidr_blocks[_] = rule_config.host_network; resource.change.after.type = rule_config.direction; resource.change.after.from_port = rule_config.from_port; resource.change.after.to_port = rule_config.to_port; resource.change.after.protocol = rule_config.protocol]
}


