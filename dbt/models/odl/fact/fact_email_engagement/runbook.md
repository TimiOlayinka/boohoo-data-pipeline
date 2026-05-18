# Runbook: fact_email_engagement

## What this model supports
Email campaign engagement fact table with delivery and conversion metrics

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
SELECT COUNT(*) FROM {{ ref('fact_email_engagement') }};

-- Check for orphan keys (fact without dimension)
-- Adapt the JOIN below for this specific model
SELECT COUNT(*) FROM {{ ref('fact_email_engagement') }} f
WHERE f.brand IS NULL;
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select fact_email_engagement`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select fact_email_engagement+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select fact_email_engagement`
- Freshness: `dbt source freshness`
