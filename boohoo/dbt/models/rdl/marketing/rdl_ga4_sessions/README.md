# rdl_ga4_sessions

## Purpose
Rdl Ga4 Sessions — RDL layer model

## Grain
One row per (session_id, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| session_id | varchar | Session identifier |
| user_pseudo_id | varchar | User Pseudo identifier |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| session_timestamp | varchar | Session timestamp |
| source | varchar | Source |
| medium | varchar | Medium |
| channel_group | varchar | Channel group |
| utm_campaign | varchar | Utm campaign |
| device_category | varchar | Device category |
| country | varchar | Country |
| landing_page | varchar | Landing page |
| page_views | varchar | Page views |
| session_duration_seconds | varchar | Session duration seconds |
| is_bounced | varchar | Boolean: bounced |
| is_engaged_session | varchar | Boolean: engaged session |
| is_new_user | varchar | Boolean: new user |
| transactions | varchar | Transactions |
| revenue | varchar | Revenue |
| add_to_carts | varchar | Add to carts |
| checkouts | varchar | Checkouts |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (session_id, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'ga4_sessions_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
