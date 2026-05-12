# boohoo_man_orders

## Purpose
Boohoo Man Orders — RDL layer model

## Grain
One row per (order_id) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| order_id | varchar | Order identifier |
| customer_id | varchar | Customer identifier |
| order_timestamp | varchar | Order timestamp |
| total_amount | varchar | Total amount |
| status | varchar | Status |
| payment_method | varchar | Payment method |
| discount_amount | varchar | Discount amount |
| shipping_cost | varchar | Shipping cost |
| item_count | varchar | Item count |
| promo_code | varchar | Promo code |
| delivery_method | varchar | Delivery method |
| fulfilment_centre | varchar | Fulfilment centre |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| brand | varchar | Boohoo Group brand name |
| source_system | varchar | Source platform identifier |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (order_id), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_boohoo_commerce', 'boohoo_man_orders_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
