# ─────────────────────────────────────────────
# Redshift Serverless (Existing — Read Only)
# ─────────────────────────────────────────────
# The Redshift cluster was provisioned manually and is connected to Looker Studio.
# We reference it here as a data source so Terraform is aware of it
# without managing its lifecycle (preventing accidental deletion).

data "aws_redshiftserverless_workgroup" "boohoo" {
  workgroup_name = "bellosdata"
}

data "aws_redshiftserverless_namespace" "boohoo" {
  namespace_name = "boohoo-dwh"
}
