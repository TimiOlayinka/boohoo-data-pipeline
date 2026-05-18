# dim_products

## Purpose
Unified product dimension with calculated margin metrics

## Grain
One row per record in dim_products

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| product_sk | varchar(200) | Surrogate key: MD5(product_id || brand) |
| product_nk | varchar(100) | Natural key from source system |
| product_name | varchar | Product name |
| colour | varchar | Colour |
| category | varchar | Category |
| subcategory | varchar | Subcategory |
| current_price | numeric(18,2) | Current price |
| cost_price | numeric(18,2) | Cost price |
| rrp | numeric(18,2) | Rrp |
| discount_pct | numeric(8,2) | Discount as percentage of RRP |
| margin | numeric(18,2) | Price minus cost |
| margin_pct | numeric(8,2) | Margin as percentage of price |
| material | varchar | Material |
| season | varchar | Season |
| is_active | boolean | Boolean: active |
| stock_status | varchar | Stock status |
| brand | varchar | Boohoo Group brand name |
| source_system | varchar | Source platform identifier |
| ingest_date | date | Date this version was loaded from source |
| dwh_created_at | varchar | Timestamp when this row was created in the warehouse |

## Key business rules
- Unifies 7 brand-level models via UNION ALL
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Contains CASE WHEN classification logic (see SQL for detail)
- Filters to is_latest = TRUE from RDL (current-state only)

## Upstream inputs
- `ref('boohoo_products')`
- `ref('boohoo_man_products')`
- `ref('plt_products')`
- `ref('nastygal_products')`
- `ref('karen_millen_products')`
- `ref('coast_products')`
- `ref('debenhams_products')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
