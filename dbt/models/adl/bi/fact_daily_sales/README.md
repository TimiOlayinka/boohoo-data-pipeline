# fact_daily_sales

## Purpose
Daily sales time series for trend analysis

## Grain
One row per record in fact_daily_sales

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| order_date | date | Order date |
| brand | varchar | Boohoo Group brand name |
| brand_tier | varchar | Brand tier: Value, Mid, or Premium |
| order_year | varchar | Order year |
| order_month | varchar | Order month |
| order_day_of_week | varchar | Order day of week |
| order_count | varchar | Order count |
| daily_revenue | varchar | Daily revenue |
| daily_net_revenue | varchar | Daily net revenue |
| avg_order_value | varchar | Avg order value |
| items_sold | varchar | Items sold |
| unique_customers | varchar | Unique customers |

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
