# fact_product_performance

## Purpose
Product performance metrics for merchandising dashboards

## Grain
One row per record in fact_product_performance

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand | varchar | Boohoo Group brand name |
| brand_tier | varchar | Brand tier: Value, Mid, or Premium |
| category | varchar | Category |
| subcategory | varchar | Subcategory |
| stock_status | varchar | Stock status |
| sku_count | varchar | Sku count |
| avg_selling_price | varchar | Avg selling price |
| avg_rrp | varchar | Avg rrp |
| avg_margin_pct | numeric(8,2) | Avg margin pct |
| avg_discount_pct | numeric(8,2) | Avg discount pct |
| active_skus | varchar | Active skus |
| inactive_skus | varchar | Inactive skus |
| ingest_date | date | Date this version was loaded from source |

## Key business rules
- Contains CASE WHEN classification logic (see SQL for detail)
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('dim_products')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
