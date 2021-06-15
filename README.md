# Localstack + Terraform + DockerCompose + GithubActions ![](https://github.com/DivakarRaju/Docker_compose_Terraform/actions/workflows/github-actions.yml/badge.svg)

This project builds Rest Api Gateway for invoking lambda function in [localstack docker container (local AWS cloud stack)](https://github.com/localstack/localstack). [Terraform container](https://hub.docker.com/r/hashicorp/terraform) is used to build the infrastructure in localstack. Used Dockercompose to manage localstack and terraform containers services. Created [GitHubActions](https://github.com/DivakarRaju/Docker_compose_Terraform/actions/workflows/github-actions.yml) for CI

### AWS services used in localstack
  1. s3
  2. ApiGateway
  3. Lambda
  4. IAM

### Usage
 1. Starting localstack service docker container in background
    > `docker-compose up -d localstack`

 2. Initializes the working directory which has terraform configuration files
    > `docker-compose run terraform init`

 3. Creates an execution plan of the infrastrucure
    > `docker-compose run terraform plan`

 4. Check the localstack service running status
    > `curl http://localhost:4566/health`

 5. Creates the Infrastracture in localstack
    > `docker-compose run terraform apply --auto-approve`

 6. Invokes the ping pong function api and prints the api response
    > `curl $(cat terraform_infra/function_url.txt)`

 7.  Stops localstack service container
      > `docker-compose down`

