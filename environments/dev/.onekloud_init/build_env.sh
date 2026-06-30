#!/bin/bash

# READ ALL SERVICES IN THIS ENVIRONMENT INTO THIS ARRAY
rm -rf ../services/README.md
allServices=($(ls ../services))
cat ../env.tfvars >> ../terraform.tfvars
for service in ${allServices[@]}; do
  echo $service
  cp ../services/${service}/service_${service}* ../
  cp ../services/${service}/policies/service_${service}* ../opa-policies
  cat ../service_${service}.tfvars >> ../terraform.tfvars
done

