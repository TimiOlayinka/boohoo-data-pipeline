# ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# Outputs
# ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

output "s3_rdl_bucket" {
  description = "S3 bucket for raw data landing"
  value       = aws_s3_bucket.rdl_staging.bucket
}

output "redshift_endpoint" {
  description = "Redshift Serverless endpoint"
  value       = data.aws_redshiftserverless_workgroup.boohoo.endpoint[0].address
}

output "redshift_namespace" {
  description = "Redshift Serverless namespace"
  value       = data.aws_redshiftserverless_namespace.boohoo.namespace_name
}

output "lambda_function_names" {
  description = "Names of all deployed Lambda functions"
  value       = [for fn in aws_lambda_function.data_generators : fn.function_name]
}
