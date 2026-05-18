# fact_orders

## Purpose
Unified order fact table with surrogate keys to dimensions

## Grain
One row per record in fact_orders

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| order_sk | varchar(200) | Surrogate key: MD5(order_id || brand) |
| order_nk | varchar(100) | Natural key from source system |
| customer_sk | varchar(200) | Surrogate key: MD5(customer_id || brand) |
| order_timestamp | date | Order timestamp |
| order_date | date | Order date |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Unifies 7 brand-level models via UNION ALL
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Filters to is_latest = TRUE from RDL (current-state only)

## Upstream inputs
- `ref('boohoo_orders')`
- `ref('boohoo_man_orders')`
- `ref('plt_orders')`
- `ref('nastygal_orders')`
- `ref('karen_millen_orders')`
- `ref('coast_orders')`
- `ref('debenhams_orders')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
