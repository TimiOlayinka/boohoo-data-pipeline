# karen_millen_customers

## Purpose
Karen Millen Customers — RDL layer model

## Grain
One row per (customer_id) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| customer_id | varchar | Customer identifier |
| email | varchar | Email |
| first_name | varchar | First name |
| last_name | varchar | Last name |
| phone | varchar | Phone |
| city | varchar | City |
| country | varchar | Country |
| customer_segment | varchar | Customer segment |
| registration_date | date | Registration date |
| gender | varchar | Gender |
| is_marketing_opted_in | boolean | Boolean: marketing opted in |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| brand | varchar | Boohoo Group brand name |
| source_system | varchar | Source platform identifier |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (customer_id), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_magento', 'karen_millen_customers_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
