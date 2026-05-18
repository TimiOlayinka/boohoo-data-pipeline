# Runbook: debenhams_orders

## What this model supports
Debenhams Orders — RDL layer model

## Expected refresh
Daily, triggered by Airflow DAG `boohoo_dbt_run`

## Failure impact
Downstream ODL and ADL models will have stale data. Dashboards may show outdated metrics.

## Common failure modes
- Source data not delivered to S3 on time
- Schema drift in source system (new/renamed/removed columns)
- Null values in natural key columns (order_id)
- Ingestion timestamp parsing failure (ISO format change)

## Diagnostics
```sql
-- Check latest ingestion date
SELECT MAX(ingest_date), COUNT(*) FROM {{ ref('debenhams_orders') }}
WHERE is_latest;

-- Check for null natural keys
SELECT COUNT(*) FROM {{ ref('debenhams_orders') }}
WHERE order_id IS NULL;

-- Check version distribution
SELECT version_count, COUNT(*) 
FROM {{ ref('debenhams_orders') }}
GROUP BY 1 ORDER BY 1 DESC LIMIT 10;
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select debenhams_orders`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select debenhams_orders+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select debenhams_orders`
- Freshness: `dbt source freshness`
