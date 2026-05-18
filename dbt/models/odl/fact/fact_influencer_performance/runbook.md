# Runbook: fact_influencer_performance

## What this model supports
Influencer post performance fact table with engagement and ROI metrics

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
SELECT COUNT(*) FROM {{ ref('fact_influencer_performance') }};

-- Check for orphan keys (fact without dimension)
-- Adapt the JOIN below for this specific model
SELECT COUNT(*) FROM {{ ref('fact_influencer_performance') }} f
WHERE f.brand IS NULL;
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select fact_influencer_performance`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select fact_influencer_performance+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select fact_influencer_performance`
- Freshness: `dbt source freshness`
