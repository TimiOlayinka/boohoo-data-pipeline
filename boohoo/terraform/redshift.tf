# ─────────────────────────────────────────────
# Redshift Serverless
# ─────────────────────────────────────────────

resource "aws_redshiftserverless_namespace" "boohoo" {
  namespace_name      = "boohoo-dwh"
  db_name             = "boohoo_dwh"
  admin_username      = var.redshift_master_username
  admin_user_password = var.redshift_master_password

  iam_roles = [data.aws_iam_role.lambda_exec_role.arn]
}

resource "aws_redshiftserverless_workgroup" "boohoo" {
  namespace_name = aws_redshiftserverless_namespace.boohoo.namespace_name
  workgroup_name = "boohoo-analytics"
  base_capacity  = 8 # Minimum RPUs — auto-scales and pauses when idle

  publicly_accessible = true

  config_parameter {
    parameter_key   = "auto_mv"
    parameter_value = "true"
  }

  config_parameter {
    parameter_key   = "enable_case_sensitive_identifier"
    parameter_value = "true"
  }
}
