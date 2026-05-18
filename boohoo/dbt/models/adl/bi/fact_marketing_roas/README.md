# fact_marketing_roas

## Purpose
Return on Ad Spend by brand × channel × period

## Grain
One row per record in fact_marketing_roas

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Contains CASE WHEN classification logic (see SQL for detail)

## Upstream inputs
- `ref('fact_marketing_spend_daily')`
- `ref('fact_ga4_sessions')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
