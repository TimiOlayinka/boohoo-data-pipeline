# Runbook: fact_email_performance

## What this model supports
Email/CRM marketing dashboard — campaign type performance and health metrics

## Expected refresh
Daily, triggered by Airflow DAG `boohoo_dbt_run`

## Failure impact
Dashboard metrics will be stale or incorrect. Executive reports may show wrong KPIs.

## Common failure modes
- Upstream ODL model failed
- Aggregation produces unexpected nulls
- Month-over-month calculation returns null for first month

## Diagnostics
```sql
-- Check date coverage
SELECT MIN(date_nk), MAX(date_nk), COUNT(DISTINCT date_nk)
FROM {{ ref('fact_email_performance') }};
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select fact_email_performance`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select fact_email_performance+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select fact_email_performance`
- Freshness: `dbt source freshness`
