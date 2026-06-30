# service_vpc_enforce_general_nacl_ingress_ports.rego
# checks aws nacl ingress rules for 0.0.0.0/0 ports 22 80 3339

package general
import data.terraform.plan_functions
import data.terraform.utility_functions
import input.resource_changes

# Resources defined in this service to which this rule applies
# aws_network_acl_rule
aws_network_acl_rules := plan_functions.get_resources_by_type("aws_network_acl_rule", resource_changes)

# SSH
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "egress": false, "from_port": 22, "to_port": 22, "protocol": "6", "rule_action": "allow"}
    resources   := plan_functions.get_matching_nacl_rule(aws_network_acl_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following NACL Rule allows %s on port %d ingress: %s", [deny_config.host_network, deny_config.from_port,resources[_].address])
}

# WEB
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "egress": false, "from_port": 80, "to_port": 80, "protocol": "6", "rule_action": "allow"}
    resources   := plan_functions.get_matching_nacl_rule(aws_network_acl_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following NACL Rule allows %s on port %d ingress: %s", [deny_config.host_network, deny_config.from_port,resources[_].address])
}

# RDP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "egress": false, "from_port": 3389, "to_port": 3389, "protocol": "6", "rule_action": "allow"}
    resources   := plan_functions.get_matching_nacl_rule(aws_network_acl_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following NACL Rule allows %s on port %d ingress: %s", [deny_config.host_network, deny_config.from_port,resources[_].address])
}

# RDP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "egress": false, "from_port": 1024, "to_port": 65535, "protocol": "6", "rule_action": "allow"}
    resources   := plan_functions.get_matching_nacl_rule(aws_network_acl_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following NACL Rule allows %s on port 3389 ingress: %s", [deny_config.host_network,resources[_].address])
}

# ICMP
deny[msg] {
    deny_config := {"host_network": "0.0.0.0/0", "egress": false, "from_port": -1, "to_port": -1, "protocol": "1", "rule_action": "allow"}
    resources   := plan_functions.get_matching_nacl_rule(aws_network_acl_rules, deny_config)
    resources   != []
    msg         := sprintf("[GENERAL] [VPC] - The following NACL Rule allows %s on port %d ingress: %s", [deny_config.host_network, deny_config.from_port,resources[_].address])
}