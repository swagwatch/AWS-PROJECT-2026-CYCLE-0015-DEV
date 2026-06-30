# service_vpc_enforce_general_security_group_ingress_ports.rego
# checks aws security group ingress rules for 0.0.0.0/0 ports 22 80 3339

package general
import data.terraform.plan_functions
import data.terraform.utility_functions
import input.resource_changes

# Resources defined in this service to which this rule applies
# aws_security_group_rule
aws_security_group_rules := plan_functions.get_resources_by_type("aws_security_group_rule", resource_changes)

# SSH
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "direction": "ingress", "from_port": 22, "to_port": 22, "protocol": "tcp"}
    resources   := plan_functions.get_matching_security_group_rule(aws_security_group_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following Security Group Rule allows %s on port %d %s: %s", [deny_config.host_network, deny_config.from_port, deny_config.direction, resources[_].address])
}

# WEB
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "direction": "ingress", "from_port": 80, "to_port": 80, "protocol": "tcp"}
    resources   := plan_functions.get_matching_security_group_rule(aws_security_group_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following Security Group Rule allows %s on port %d %s: %s", [deny_config.host_network, deny_config.from_port, deny_config.direction, resources[_].address])
}

# RDP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "direction": "ingress", "from_port": 3389, "to_port": 3389, "protocol": "tcp"}
    resources   := plan_functions.get_matching_security_group_rule(aws_security_group_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following Security Group Rule allows %s on port %d %s: %s", [deny_config.host_network, deny_config.from_port, deny_config.direction, resources[_].address])
}

# RDP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "direction": "ingress", "from_port": 1024, "to_port": 65535, "protocol": "tcp"}
    resources   := plan_functions.get_matching_security_group_rule(aws_security_group_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following Security Group Rule allows %s on port 3389 %s: %s", [deny_config.host_network, deny_config.direction, resources[_].address])
}

# ICMP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "direction": "ingress", "from_port": -1, "to_port": -1, "protocol": "icmp"}
    resources   := plan_functions.get_matching_security_group_rule(aws_security_group_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following Security Group Rule allows %s on port %d %s: %s", [deny_config.host_network, deny_config.from_port, deny_config.direction, resources[_].address])
}
