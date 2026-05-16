provider "aws" {
  region  = "eu-west-2"
  profile = "playEngineer"
}

# ═══════════════════════════════════════════════════════════════
# IAM ROLES — Managed via AWS CLI (PowerUserAccess cannot list/read IAM policies)
# Roles created and policies attached in AWUJOO-019 session.
# ═══════════════════════════════════════════════════════════════
#
# Role: ecs_execution_role
#   ARN: arn:aws:iam::332779204498:role/ecs_execution_role
#   Attached: AmazonECSTaskExecutionRolePolicy
#
# Role: ledger-cloud-api-role
#   ARN: arn:aws:iam::332779204498:role/ledger-cloud-api-role
#   Attached: AWSLambdaBasicExecutionRole, AmazonS3ReadOnlyAccess
#

locals {
  ecs_execution_role_arn = "arn:aws:iam::332779204498:role/ecs_execution_role"
  ledger_api_role_arn    = "arn:aws:iam::332779204498:role/ledger-cloud-api-role"
}

# ═══════════════════════════════════════════════════════════════
# ECR + ECS Fargate (Pipeline Containers)
# ═══════════════════════════════════════════════════════════════

# 1. ECR Repository
resource "aws_ecr_repository" "data_pipelines" {
  name                 = "bellosdata-pipelines"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "bellosdata_cluster" {
  name = "bellosdata-cluster"
}

# 3. ECS Task Definition
resource "aws_ecs_task_definition" "pipeline_task" {
  family                   = "bellosdata-pipeline-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Minimal CPU
  memory                   = "512" # Minimal Memory
  execution_role_arn       = local.ecs_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "pipeline-container"
      image     = aws_ecr_repository.data_pipelines.repository_url
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/bellosdata-pipeline"
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 4. CloudWatch Log Group (ECS)
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/bellosdata-pipeline"
  retention_in_days = 7
}

# ═══════════════════════════════════════════════════════════════
# Lambda Cloud API — The Light That Never Goes Out
# AWUJOO-018: Genesis Block Architecture
# AWUJOO-019: Cloud Light Activation (deployed via CLI)
# ═══════════════════════════════════════════════════════════════

# Lambda function deployed via CLI in AWUJOO-019 session.
# Function: ledger-cloud-api
# ARN: arn:aws:lambda:eu-west-2:332779204498:function:ledger-cloud-api
#
# API Gateway resources managed here for drift detection.

# 5. CloudWatch Log Group (Lambda)
resource "aws_cloudwatch_log_group" "ledger_api_logs" {
  name              = "/aws/lambda/ledger-cloud-api"
  retention_in_days = 7
}

# 6. API Gateway (HTTP API v2 — cheaper than REST)
resource "aws_apigatewayv2_api" "ledger_api" {
  name          = "ledger-cloud-api"
  protocol_type = "HTTP"
  description   = "Merchant Ledger Cloud API — The Light That Never Goes Out"
}

# 7. API Gateway Stage (auto-deploy)
resource "aws_apigatewayv2_stage" "ledger_default" {
  api_id      = aws_apigatewayv2_api.ledger_api.id
  name        = "$default"
  auto_deploy = true
}

# ═══════════════════════════════════════════════════════════════
# BellosData Lakehouse — Governance Layer
# MIGRATED: Glue + Athena → Unity Catalog OSS + DuckDB
# Sprint S1 (AWUJOO-027) → Unity Migration (2026-05-16)
#
# Unity Catalog runs locally via Docker Compose:
#   Server: http://localhost:8070
#   UI:     http://localhost:3000
#   Config: unity-catalog/compose.yaml
#
# Query engine: DuckDB (connects directly to Unity Catalog API)
#
# Former resources (DELETED from AWS):
#   - aws_s3_bucket.athena_results (playdarch-athena-results)
#   - aws_glue_catalog_database.lakehouse (bellosdata_lakehouse)
#   - aws_athena_workgroup.analytics (bellosdata-analytics)
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# Outputs
# ═══════════════════════════════════════════════════════════════

output "ecr_repository_url" {
  value       = aws_ecr_repository.data_pipelines.repository_url
  description = "ECR repository URL for pipeline containers"
}

output "ledger_api_url" {
  value       = aws_apigatewayv2_api.ledger_api.api_endpoint
  description = "Cloud API URL — The Light That Never Goes Out"
}

output "ledger_api_id" {
  value       = aws_apigatewayv2_api.ledger_api.id
  description = "API Gateway ID"
}

