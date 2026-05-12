# fact_customer_segments

## Purpose
Customer segmentation analysis for CRM dashboards

## Grain
One row per record in fact_customer_segments

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand | varchar | Boohoo Group brand name |
| brand_tier | varchar | Brand tier: Value, Mid, or Premium |
| customer_segment | varchar | Customer segment |
| gender | varchar | Gender |
| country | varchar | Country |
| customer_count | varchar | Customer count |
| opted_in_count | varchar | Opted in count |
| opt_in_rate_pct | numeric(8,2) | Opt in rate pct |
| earliest_registration | varchar | Earliest registration |
| latest_registration | varchar | Latest registration |
| ingest_date | date | Date this version was loaded from source |

## Key business rules
- Contains CASE WHEN classification logic (see SQL for detail)
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('dim_customers')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
