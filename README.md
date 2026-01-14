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
module "malik_ecs" {
  source = "git::https://github.com/rjones18/AWS-ECS-TERRAFORM-MODULE.git?ref=main"

  name = "${var.app_name}-${var.environment}"

  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  image          = var.ecr_image
  container_port = var.container_port

  desired_count = var.desired_count
  cpu           = var.cpu
  memory        = var.memory

  health_check_path = "/"

  env = {
    FLASK_ENV = var.environment
    APP_NAME  = var.app_name
  }

  secrets = {
    MALIK_SECRETS_NAME = var.secrets_manager_arn
  }

  secretsmanager_arns = [
    var.secrets_manager_arn
  ]

  # ✅ NEW: HTTPS
  enable_https           = true
  redirect_http_to_https = true
  acm_certificate_arn    = aws_acm_certificate_validation.app.certificate_arn
  # ssl_policy           = "ELBSecurityPolicy-TLS13-1-2-2021-06" # optional if your module has this var

  tags = var.tags
}


