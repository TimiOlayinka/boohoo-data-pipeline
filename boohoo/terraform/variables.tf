# ─────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}
