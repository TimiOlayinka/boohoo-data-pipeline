# Runbook: rdl_ga4_sessions

## What this model supports
Rdl Ga4 Sessions — RDL layer model

## Expected refresh
Daily, triggered by Airflow DAG `boohoo_dbt_run`

## Failure impact
Downstream ODL and ADL models will have stale data. Dashboards may show outdated metrics.

## Common failure modes
- Source data not delivered to S3 on time
- Schema drift in source system (new/renamed/removed columns)
- Null values in natural key columns (session_id, brand)
- Ingestion timestamp parsing failure (ISO format change)

## Diagnostics
```sql
-- Check latest ingestion date
SELECT MAX(ingest_date), COUNT(*) FROM {{ ref('rdl_ga4_sessions') }}
WHERE is_latest;

-- Check for null natural keys
SELECT COUNT(*) FROM {{ ref('rdl_ga4_sessions') }}
WHERE session_id IS NULL OR brand IS NULL;

-- Check version distribution
SELECT version_count, COUNT(*) 
FROM {{ ref('rdl_ga4_sessions') }}
GROUP BY 1 ORDER BY 1 DESC LIMIT 10;
```

## Recovery steps
1. Check Airflow DAG logs for the failing task
2. Verify source data exists in S3 (`s3://data-lake/inbox/`)
3. Re-run the specific model: `dbt run --select rdl_ga4_sessions`
4. If schema drift: update the RDL model SQL and re-run
5. Verify downstream models: `dbt run --select rdl_ga4_sessions+`

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select rdl_ga4_sessions`
- Freshness: `dbt source freshness`
