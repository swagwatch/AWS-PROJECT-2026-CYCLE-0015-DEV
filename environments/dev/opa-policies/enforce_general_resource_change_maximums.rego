# enforce_resource_change_maximums.rego
# checks for resource maximums

package general
import data.terraform.plan_functions
import data.terraform.utility_functions
import input.resource_changes


# Change maximums
max_additions := 10
max_deletions := 10
max_modifications := 10


# Get different resource change types
# Get all creates
resources_added := plan_functions.get_resources_by_action("create", resource_changes)

# Get all deletes
resources_removed := plan_functions.get_resources_by_action("delete", resource_changes)

# Get all modifies
resource_changed := plan_functions.get_resources_by_action("update", resource_changes)

# Check to see if there are too many changes
warn[msg] {
    count(resources_added) > max_additions
    msg := sprintf("[GENERAL] - Too many resources added. Only %d resources can be added at a time.", [max_additions])
}

deny[msg] {
    count(resources_removed) > max_deletions
    msg := sprintf("[GENERAL] - Too many resources deleted. Only %d resources can be added at a time.", [max_deletions])
}

warn[msg] {
    count(resource_changed) > max_modifications
    msg := sprintf("[GENERAL] - Too many resources updated. Only %d resources can be added at a time.", [max_modifications])
}