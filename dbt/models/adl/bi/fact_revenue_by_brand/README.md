# fact_revenue_by_brand

## Purpose
Pre-aggregated revenue metrics by brand - feeds Looker Studio

## Grain
One row per record in fact_revenue_by_brand

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| ingest_date | date | Date this version was loaded from source |
| brand | varchar | Boohoo Group brand name |
| brand_tier | varchar | Brand tier: Value, Mid, or Premium |
| total_orders | varchar | Total orders |
| unique_customers | varchar | Unique customers |
| gross_revenue | numeric(18,2) | Total amount + shipping cost |
| net_revenue | numeric(18,2) | Total amount - discount |
| total_discounts | varchar | Total discounts |
| avg_order_value | varchar | Avg order value |
| discount_rate_pct | numeric(8,2) | Discount rate pct |
| total_items_sold | varchar | Total items sold |

## Key business rules
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('fact_orders')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
