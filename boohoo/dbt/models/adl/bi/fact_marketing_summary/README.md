# fact_marketing_summary

## Purpose
Executive summary — the "wow" table for client presentations

## Grain
One row per (brand)

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| ROUND( | varchar | Round( |
| (total_spend - LAG(total_spend) OVER (PARTITION BY brand ORDER BY month_start)) | varchar | (total spend - lag(total spend) over (partition by brand order by month start)) |
| / NULLIF(LAG(total_spend) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1) | varchar | / nullif(lag(total spend) over (partition by brand order by month start), 0) * 100, 1) |
| spend_mom_growth_pct | numeric(8,2) | Spend mom growth pct |
| ROUND( | varchar | Round( |
| (total_revenue - LAG(total_revenue) OVER (PARTITION BY brand ORDER BY month_start)) | varchar | (total revenue - lag(total revenue) over (partition by brand order by month start)) |
| / NULLIF(LAG(total_revenue) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1) | varchar | / nullif(lag(total revenue) over (partition by brand order by month start), 0) * 100, 1) |
| revenue_mom_growth_pct | numeric(8,2) | Revenue mom growth pct |
| ROUND( | varchar | Round( |
| (blended_roas - LAG(blended_roas) OVER (PARTITION BY brand ORDER BY month_start)) | varchar | (blended roas - lag(blended roas) over (partition by brand order by month start)) |
| / NULLIF(LAG(blended_roas) OVER (PARTITION BY brand ORDER BY month_start), 0) * 100, 1) | varchar | / nullif(lag(blended roas) over (partition by brand order by month start), 0) * 100, 1) |
| roas_mom_growth_pct | numeric(8,2) | Roas mom growth pct |

## Key business rules
- Contains CASE WHEN classification logic (see SQL for detail)

## Upstream inputs
- `ref('fact_marketing_spend_daily')`
- `ref('fact_ga4_sessions')`
- `ref('fact_email_engagement')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
