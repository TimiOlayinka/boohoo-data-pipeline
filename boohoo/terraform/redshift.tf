# ─────────────────────────────────────────────
# Redshift Serverless — Fully Managed
# ─────────────────────────────────────────────
# Manages the Redshift Serverless namespace and workgroup.
# Schemas are created via a null_resource provisioner
# running post-deployment SQL.

resource "aws_redshiftserverless_namespace" "boohoo" {
  namespace_name      = "boohoo-dwh"
  db_name             = "boohoo_dwh"
  admin_username      = var.redshift_admin_user
  admin_user_password = var.redshift_admin_password
  iam_roles           = [aws_iam_role.redshift_s3_role.arn]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "boohoo-dwh-namespace"
  }
}

resource "aws_redshiftserverless_workgroup" "boohoo" {
  workgroup_name = "bellosdata"
  namespace_name = aws_redshiftserverless_namespace.boohoo.namespace_name
  base_capacity  = 8

  publicly_accessible = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "boohoo-dwh-workgroup"
  }
}

# ─────────────────────────────────────────────
# Post-Provisioning: Create Schemas
# ─────────────────────────────────────────────
# Creates all required schemas including the new
# unit_test schema for data quality staging.

resource "null_resource" "redshift_schemas" {
  depends_on = [aws_redshiftserverless_workgroup.boohoo]

  provisioner "local-exec" {
    command = <<-EOT
      aws redshift-data execute-statement \
        --workgroup-name "${aws_redshiftserverless_workgroup.boohoo.workgroup_name}" \
        --database "${aws_redshiftserverless_namespace.boohoo.db_name}" \
        --sql "
          CREATE SCHEMA IF NOT EXISTS rdl_boohoo_commerce;
          CREATE SCHEMA IF NOT EXISTS rdl_salesforce_commerce;
          CREATE SCHEMA IF NOT EXISTS rdl_shopify;
          CREATE SCHEMA IF NOT EXISTS rdl_magento;
          CREATE SCHEMA IF NOT EXISTS rdl_oracle_commerce;
          CREATE SCHEMA IF NOT EXISTS rdl_marketing;
          CREATE SCHEMA IF NOT EXISTS odl;
          CREATE SCHEMA IF NOT EXISTS bi;
          CREATE SCHEMA IF NOT EXISTS unit_test;
        " \
        --region ${var.aws_region}
    EOT
  }

  triggers = {
    # Re-run if schema list changes
    schema_hash = sha256("rdl_boohoo_commerce,rdl_salesforce_commerce,rdl_shopify,rdl_magento,rdl_oracle_commerce,rdl_marketing,odl,bi,unit_test")
  }
}

# ─────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────

output "redshift_workgroup_endpoint" {
  description = "Redshift Serverless workgroup endpoint"
  value       = aws_redshiftserverless_workgroup.boohoo.endpoint
}

output "redshift_namespace_id" {
  description = "Redshift namespace ID"
  value       = aws_redshiftserverless_namespace.boohoo.namespace_id
}
