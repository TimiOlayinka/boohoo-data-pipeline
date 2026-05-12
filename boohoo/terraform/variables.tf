# ─────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "redshift_admin_user" {
  description = "Redshift Serverless admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "redshift_admin_password" {
  description = "Redshift Serverless admin password"
  type        = string
  sensitive   = true
}

variable "parquet_export_bucket" {
  description = "S3 bucket for Parquet exports from Redshift"
  type        = string
  default     = "boohoo-data-quality-staging"
}
