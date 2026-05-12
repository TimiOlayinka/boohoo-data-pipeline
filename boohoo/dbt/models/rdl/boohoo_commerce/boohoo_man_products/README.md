# boohoo_man_products

## Purpose
Boohoo Man Products — RDL layer model

## Grain
One row per (product_id) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| product_id | varchar | Product identifier |
| product_name | varchar | Product name |
| colour | varchar | Colour |
| category | varchar | Category |
| subcategory | varchar | Subcategory |
| current_price | varchar | Current price |
| cost_price | varchar | Cost price |
| rrp | varchar | Rrp |
| material | varchar | Material |
| season | varchar | Season |
| is_active | varchar | Boolean: active |
| stock_status | varchar | Stock status |
| created_at | varchar | Created at |
| updated_at | varchar | Updated at |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| brand | varchar | Boohoo Group brand name |
| source_system | varchar | Source platform identifier |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (product_id), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_boohoo_commerce', 'boohoo_man_products_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
