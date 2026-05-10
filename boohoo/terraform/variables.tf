# ─────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────

variable "redshift_master_password" {
  description = "Master password for the Redshift cluster"
  type        = string
  sensitive   = true
}

variable "redshift_master_username" {
  description = "Master username for the Redshift cluster"
  type        = string
  default     = "admin"
}

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}
