# Runbook: dim_time

## What this model supports
Conformed date dimension providing consistent date attributes across all facts and reports.

## Expected refresh
Daily, triggered by Airflow DAG `boohoo_dbt_run`

## Failure impact
All time-based joins in fact tables will fail. Dashboards relying on date filters will break.

## Common failure modes
- Date spine generator (`pg_class LIMIT 1096`) exhausted if source table has fewer rows
- Year rollover: spine ends at 2024-01-01 + 1096 days (~3 years). Will need extension by Jan 2027.
- Timezone: all dates are UTC with no timezone conversion

## Diagnostics
```sql
-- Check date range coverage
SELECT MIN(date_day), MAX(date_day), COUNT(*) FROM {{ ref('dim_time') }};

-- Check for gaps
SELECT date_day + INTERVAL '1 day' AS expected, b.date_day AS actual
FROM {{ ref('dim_time') }} a
LEFT JOIN {{ ref('dim_time') }} b ON a.date_day + INTERVAL '1 day' = b.date_day
WHERE b.date_day IS NULL AND a.date_day < (SELECT MAX(date_day) FROM {{ ref('dim_time') }});
```

## Recovery steps
1. This model is deterministic — simply re-run: `dbt run --select dim_time`
2. To extend the range, increase the `LIMIT 1096` value in the SQL

## Escalation
data-team@boohoo.com

## Related checks
- dbt test: `dbt test --select dim_time`
