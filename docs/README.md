# Powered By OneKloud 

### Project Setup
- Enable Github Actions On This Repository
- Create The Following Repository Secrets
  - AWS_K_ID : AWS KEY
  - AWS_S_ID : AWS Secret Key
  - CROSS_REPO_TOKEN : Github User PAT
- Clone this repository

### Environment Setup 
- Clone Remote Branch (example)
  - git checkout -b feature/deploy-dev-vpc-service
  - git pull origin feature/deploy-dev-vpc-service
- Change To Appropriate Environment Directory (example)
  - cd environments/dev
- Update tf_backend.tf and replace BUCKETNAME PROJECTNAME placeholder with S3 bucket and DynamoDB Table Name

### Service Setup
- Change to Appropriate Service Directory (example)
  - cd services/vpc
- Update service-service_name.tfvars file with appropriate values

### Pull Request Automation
- Change Directory To The Root Of This Project
- Create Pull Request
  - git status
  - git add A .
  - git status
  - git commit -m "commit message here"
  - git push origin feature/deploy-dev-vpc-service
- Compare and create pull request (runs terraform plan)
- Review terraform plan by clicking the github action
- Apply terraform plan by placing this comment on this pull request (example)
  - terraform apply dev
- Help can be accessed by placing this comment on this pull request
  - terraform help
- If all goes well merge this pull request to main
- Delete this branch
- Then on local machine
  - git checkout main
  - git pull origin main
  - git branch -D feature/deploy-dev-vpc-service

