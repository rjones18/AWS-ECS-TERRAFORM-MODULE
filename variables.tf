variable "name" {
  description = "Base name for resources (service/cluster/alb/etc.)"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnets for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for ECS tasks"
  type        = list(string)
}

variable "image" {
  description = "ECR image URI (e.g., 123.dkr.ecr.us-east-1.amazonaws.com/repo:tag)"
  type        = string
}

variable "container_port" {
  type    = number
  default = 5001
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  description = "Fargate CPU (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate memory (MB). Must be valid pairing with cpu."
  type        = number
  default     = 1024
}

variable "assign_public_ip" {
  description = "If true, tasks get public IPs (usually false for private subnets)"
  type        = bool
  default     = false
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "env" {
  description = "Plain environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Container secrets. Map of ENV_VAR_NAME => Secrets Manager ARN (or SSM parameter ARN)."
  type        = map(string)
  default     = {}
}

variable "secretsmanager_arns" {
  description = "Secrets Manager ARNs the task role should be allowed to read."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_https" {
  description = "Enable HTTPS listener (443) using ACM certificate."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN to attach to the ALB HTTPS listener (required if enable_https=true)."
  type        = string
  default     = null
}

variable "redirect_http_to_https" {
  description = "Redirect HTTP (80) to HTTPS (443). Requires enable_https=true."
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "ALB SSL policy."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
