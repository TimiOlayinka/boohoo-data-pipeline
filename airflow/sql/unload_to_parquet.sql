-- ─────────────────────────────────────────────────────────────────
-- UNLOAD Template: Export a Redshift table to S3 as Parquet
-- Parameters (injected by Airflow):
--   {schema}  - Redshift schema name
--   {table}   - Table/view name
--   {filter}  - Optional WHERE clause (e.g. "WHERE is_latest")
--   {s3_path} - Target S3 path (e.g. s3://bucket/layer/model/date/)
--   {iam_role} - IAM role ARN for S3 access
-- ─────────────────────────────────────────────────────────────────

UNLOAD ('SELECT * FROM {schema}.{table} {filter}')
TO '{s3_path}'
IAM_ROLE '{iam_role}'
FORMAT AS PARQUET
ALLOWOVERWRITE
PARALLEL OFF;
