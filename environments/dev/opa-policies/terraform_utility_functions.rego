# terraform_utility_functions.rego
# Provides other useful functions

package terraform.utility_functions

# Keywords [  ]
import future.keywords

# Tag checking functions
# Read all tags from a resource
readTags(resource) = tags {
    tags = resource.change.after.tags
}

# Check if tag is present for a given resource
findTag(resource, tagName) if {
    readTags(resource)[tagName]
}

# Check if tag has proper value for a given resource
findValue(resource, tagName, tagValue) if {
    readTags(resource)[tagName] == tagValue
}

# Check if all tags are present for a given resource
missingTags(resource, tagList) if {
    keys := { key | resource.change.after.tags[key] }
    missing := tagList - keys
    missing == set()
}

# Check if resource contains required tags
tags_contain_required(resource_checks,req_tags) = resources {
    resources := [ resource | 
      resource := resource_checks[_]
      not (missingTags(resource, req_tags))
    ]
}
