variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}


# ------------------
# Networking (VPC)
# ------------------
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

# ------------------
# ECS / App settings
# ------------------
variable "app_name" {
  type = string
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 1024
}

variable "memory" {
  type    = number
  default = 2048
}

variable "ecr_image" {
  description = "Full ECR image URI with tag"
  type        = string
}

# ------------------
# Secrets
# ------------------
variable "secrets_manager_arn" {
  description = "Secrets Manager ARN containing Malik secrets"
  type        = string
}

# ------------------
# Tags
# ------------------
variable "tags" {
  type    = map(string)
  default = {}
}

variable "hosted_zone_name" {
  description = "Existing Route53 zone name, e.g. example.com."
  type        = string
}

variable "app_fqdn" {
  description = "Full DNS name for the app, e.g. streamflix.example.com"
  type        = string
}
