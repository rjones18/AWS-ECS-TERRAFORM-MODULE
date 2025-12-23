module "malik_ecs" {
  source = "../"

  name = "${var.app_name}-${var.environment}"

  # ------------------
  # Networking
  # ------------------
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  # ------------------
  # Container
  # ------------------
  image          = var.ecr_image
  container_port = var.container_port

  desired_count = var.desired_count
  cpu           = var.cpu
  memory        = var.memory

  health_check_path = "/"

  # ------------------
  # App env vars
  # ------------------
  env = {
    FLASK_ENV = var.environment
    APP_NAME  = var.app_name
  }

  # ------------------
  # Secrets injection
  # ------------------
  secrets = {
    MALIK_SECRETS_NAME = var.secrets_manager_arn
  }

  secretsmanager_arns = [
    var.secrets_manager_arn
  ]

  tags = var.tags
}

