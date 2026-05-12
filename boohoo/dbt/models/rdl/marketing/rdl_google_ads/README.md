# rdl_google_ads

## Purpose
Rdl Google Ads — RDL layer model

## Grain
One row per (ad_id, date_day, device, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| customer_id | varchar | Customer identifier |
| customer_name | varchar | Customer name |
| campaign_id | varchar | Campaign identifier |
| campaign_name | varchar | Campaign name |
| campaign_status | varchar | Campaign status |
| channel_type | varchar | Channel type |
| ad_group_id | varchar | Ad Group identifier |
| ad_id | varchar | Ad identifier |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| device | varchar | Device |
| ad_network_type | varchar | Ad network type |
| cost_micros | varchar | Cost micros |
| spend | varchar | Spend |
| impressions | varchar | Impressions |
| clicks | varchar | Clicks |
| interactions | varchar | Interactions |
| conversions | varchar | Conversions |
| conversions_value | varchar | Conversions value |
| all_conversions | varchar | All conversions |
| all_conversions_value | varchar | All conversions value |
| video_quartile_p25_rate | varchar | Video quartile p25 rate |
| video_quartile_p50_rate | varchar | Video quartile p50 rate |
| video_quartile_p75_rate | varchar | Video quartile p75 rate |
| video_quartile_p100_rate | varchar | Video quartile p100 rate |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (ad_id, date_day, device, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'google_ads_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
