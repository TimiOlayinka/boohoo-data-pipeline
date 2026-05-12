# Runbook: dim_customers

## What this model supports
Unified customer dimension across all Boohoo Group brands (star schema)

## Expected refresh
Daily, triggered by Airflow DAG `boohoo_dbt_run`

## Failure impact
Downstream ADL aggregates and dashboards will be affected.

## Common failure modes
- Upstream RDL model failed or returned empty
- Join key mismatch between fact and dimension
- Surrogate key collision (MD5 hash collision — extremely rare)
- is_latest filter returns no rows (ingestion issue)

## Diagnostics
```sql
-- Check row count vs yesterday
SELECT COUNT(*) FROM {{ ref('dim_customers') }};

-- Check for orphan keys (fact without dimension)
-- Adapt the JOIN below for this specific model
SELECT COUNT(*) FROM {{ ref('dim_customers') }} f
WHERE f.brand IS NULL;
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select dim_customers`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select dim_customers+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select dim_customers`
- Freshness: `dbt source freshness`
