# Terraform AWS ECS Service with Application Load Balancer

This Terraform module deploys a **containerized application on AWS ECS (Fargate)** behind an **Application Load Balancer (ALB)**.

It is designed for production-ready web applications such as **Flask, FastAPI, Node.js**, and supports:

- Private ECS tasks
- Public ALB ingress
- Secrets injection (AWS Secrets Manager / SSM)
- CloudWatch logging
- Least-privilege IAM roles

---

## Features

- ✅ ECS Cluster (Fargate)
- ✅ ECS Task Definition
- ✅ ECS Service
- ✅ Application Load Balancer (ALB)
- ✅ Target Group + Listener (HTTP)
- ✅ Security Groups (ALB → ECS)
- ✅ CloudWatch Logs
- ✅ IAM Execution Role (ECR pull, logs)
- ✅ IAM Task Role (runtime AWS API access)
- ✅ Secrets injection into containers
- ✅ Configurable CPU, memory, desired count

---

## Requirements

| Name | Version |
|-----|---------|
| terraform | >= 1.5 |
| aws provider | >= 5.0 |

---


## Usage

### Basic Example

```hcl
module "ecs_service" {
  source = "./modules/ecs-service-alb"

  name = "malik-ai"

  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  image          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/malik-ai:latest"
  container_port = 5001

  desired_count = 1
  cpu           = 1024
  memory        = 2048

  env = {
    FLASK_ENV = "prod"
  }

  secrets = {
    MALIK_SECRETS_NAME = "arn:aws:secretsmanager:us-east-1:123456789012:secret:MALIK_SECRETS-AbCdEf"
  }

  secretsmanager_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:MALIK_SECRETS-AbCdEf"
  ]

  tags = {
    Project = "malik-ai"
    Env     = "prod"
  }
}


