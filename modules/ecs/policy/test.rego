package terraform.aws.ecs

import data.terraform.aws.ecs

# Helper to count items
count(arr) = n if {
  n := sum([1 | arr[_]])
}

# =====================================================
# Test 1: Valid configuration - should have no denies
# =====================================================

test_valid_configuration_no_violations if {
  result := deny with input as valid_ecs_config
  count(result) == 0
}

valid_ecs_config := {
  "resource_changes": [
    {
      "type": "aws_ecs_cluster",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "dev-cluster",
          "tags": {
            "Environment": "dev",
            "Owner": "platform-team"
          },
          "setting": [
            {
              "name": "containerInsights",
              "value": "enabled"
            }
          ]
        }
      }
    },
    {
      "type": "aws_ecs_task_definition",
      "change": {
        "actions": ["create"],
        "after": {
          "family": "app-task",
          "network_mode": "awsvpc",
          "requires_compatibilities": ["FARGATE"],
          "execution_role_arn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          "task_role_arn": "arn:aws:iam::123456789012:role/ecsTaskRole",
          "cpu": "256",
          "memory": "512",
          "container_definitions": "[{\"name\":\"app\",\"image\":\"nginx:latest\",\"readonlyRootFilesystem\":true}]",
          "tags": {
            "Environment": "dev",
            "Owner": "platform-team"
          }
        }
      }
    },
    {
      "type": "aws_ecs_service",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "app-service",
          "launch_type": "FARGATE",
          "network_configuration": [
            {
              "assign_public_ip": false
            }
          ],
          "tags": {
            "Environment": "dev",
            "Owner": "platform-team"
          }
        }
      }
    },
    {
      "type": "aws_security_group_rule",
      "change": {
        "actions": ["create"],
        "after": {
          "type": "ingress",
          "from_port": 80,
          "to_port": 80,
          "protocol": "tcp",
          "cidr_blocks": ["10.0.0.0/16"],
          "description": "Allow HTTP from VPC"
        }
      }
    },
    {
      "type": "aws_cloudwatch_log_group",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "/ecs/dev-cluster/app-task",
          "retention_in_days": 7,
          "tags": {
            "Environment": "dev",
            "Owner": "platform-team"
          }
        }
      }
    }
  ]
}

# =====================================================
# Test 2: Invalid configuration - multiple violations
# =====================================================

test_invalid_configuration_with_violations if {
  result := deny with input as invalid_ecs_config
  count(result) > 0
}

test_invalid_configuration_has_missing_tags_violation if {
  result := deny with input as invalid_ecs_config
  violations := [msg | msg := result[_]; contains(msg, "missing required tag")]
  count(violations) > 0
}

test_invalid_configuration_has_network_mode_violation if {
  result := deny with input as invalid_ecs_config
  violations := [msg | msg := result[_]; contains(msg, "awsvpc")]
  count(violations) > 0
}

test_invalid_configuration_has_execution_role_violation if {
  result := deny with input as invalid_ecs_config
  violations := [msg | msg := result[_]; contains(msg, "execution_role_arn")]
  count(violations) > 0
}

test_invalid_configuration_has_security_group_violation if {
  result := deny with input as invalid_ecs_config
  violations := [msg | msg := result[_]; contains(msg, "unrestricted access")]
  count(violations) > 0
}

invalid_ecs_config := {
  "resource_changes": [
    {
      "type": "aws_ecs_cluster",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "prod-cluster",
          "tags": {
            "Environment": "prod"
          },
          "setting": []
        }
      }
    },
    {
      "type": "aws_ecs_task_definition",
      "change": {
        "actions": ["create"],
        "after": {
          "family": "insecure-task",
          "network_mode": "bridge",
          "requires_compatibilities": ["FARGATE"],
          "cpu": "256",
          "memory": "512",
          "container_definitions": "[{\"name\":\"app\",\"image\":\"nginx:latest\"}]",
          "tags": {}
        }
      }
    },
    {
      "type": "aws_ecs_service",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "insecure-service",
          "launch_type": "FARGATE",
          "network_configuration": [
            {
              "assign_public_ip": true
            }
          ],
          "tags": {
            "Environment": "prod"
          }
        }
      }
    },
    {
      "type": "aws_security_group_rule",
      "change": {
        "actions": ["create"],
        "after": {
          "type": "ingress",
          "from_port": 22,
          "to_port": 22,
          "protocol": "tcp",
          "cidr_blocks": ["0.0.0.0/0"],
          "description": "Allow SSH from everywhere"
        }
      }
    },
    {
      "type": "aws_cloudwatch_log_group",
      "change": {
        "actions": ["create"],
        "after": {
          "name": "/ecs/prod-cluster/insecure-task",
          "retention_in_days": 7,
          "tags": {
            "Environment": "prod",
            "Owner": "platform-team"
          }
        }
      }
    }
  ]
}

# =====================================================
# Test 3: Delete action - should not trigger violations
# =====================================================

test_delete_action_ignored if {
  result := deny with input as delete_ecs_config
  count(result) == 0
}

delete_ecs_config := {
  "resource_changes": [
    {
      "type": "aws_ecs_cluster",
      "change": {
        "actions": ["delete"],
        "after": null,
        "before": {
          "name": "old-cluster",
          "tags": {}
        }
      }
    },
    {
      "type": "aws_ecs_service",
      "change": {
        "actions": ["delete"],
        "after": null,
        "before": {
          "name": "old-service",
          "tags": {}
        }
      }
    },
    {
      "type": "aws_ecs_task_definition",
      "change": {
        "actions": ["delete"],
        "after": null,
        "before": {
          "family": "old-task",
          "tags": {}
        }
      }
    }
  ]
}
