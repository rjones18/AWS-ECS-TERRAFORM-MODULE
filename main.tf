terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ---------------------------
# CloudWatch Logs
# ---------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

# ---------------------------
# ECS Cluster
# ---------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
  tags = var.tags
}

# ---------------------------
# Security Groups
# ---------------------------

# ALB SG: inbound 80 from internet; outbound to ECS
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS SG: inbound ONLY from ALB SG to container_port; outbound all
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "ECS task security group"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    description     = "From ALB to container"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# ALB + Target Group + Listener
# ---------------------------
resource "aws_lb" "this" {
  name               = substr("${var.name}-alb", 0, 32)
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  tags               = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = substr("${var.name}-tg", 0, 32)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ---------------------------
# IAM: Execution role (ECR pull, logs)
# ---------------------------
data "aws_iam_policy_document" "ecs_task_exec_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------
# IAM: Task role (runtime AWS API access)
# ---------------------------
resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "secrets_read" {
  count = length(var.secretsmanager_arns) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.secretsmanager_arns
  }
}

# Allow EXECUTION role to pull container secrets during task startup
data "aws_iam_policy_document" "execution_secrets_read" {
  count = length(var.secretsmanager_arns) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.secretsmanager_arns
  }
}

resource "aws_iam_policy" "execution_secrets_read" {
  count  = length(var.secretsmanager_arns) > 0 ? 1 : 0
  name   = "${var.name}-exec-secrets-read"
  policy = data.aws_iam_policy_document.execution_secrets_read[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_secrets_read_attach" {
  count      = length(var.secretsmanager_arns) > 0 ? 1 : 0
  role       = aws_iam_role.execution.name
  policy_arn  = aws_iam_policy.execution_secrets_read[0].arn
}


resource "aws_iam_policy" "secrets_read" {
  count  = length(var.secretsmanager_arns) > 0 ? 1 : 0
  name   = "${var.name}-secrets-read"
  policy = data.aws_iam_policy_document.secrets_read[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "task_secrets_read" {
  count      = length(var.secretsmanager_arns) > 0 ? 1 : 0
  role       = aws_iam_role.task.name
  policy_arn  = aws_iam_policy.secrets_read[0].arn
}

# ---------------------------
# ECS Task Definition + Service
# ---------------------------

locals {
  env_list = [
    for k, v in var.env : { name = k, value = v }
  ]

  secrets_list = [
    for k, arn in var.secrets : { name = k, valueFrom = arn }
  ]

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true

      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]

      environment = local.env_list
      secrets     = local.secrets_list

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = local.container_definitions
  tags                 = var.tags
}

resource "aws_ecs_service" "this" {
  name            = "${var.name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}
