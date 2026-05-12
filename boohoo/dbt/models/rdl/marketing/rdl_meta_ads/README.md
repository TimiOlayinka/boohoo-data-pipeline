# rdl_meta_ads

## Purpose
Rdl Meta Ads — RDL layer model

## Grain
One row per (campaign_id, date_start, publisher_platform, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| campaign_id | varchar | Campaign identifier |
| campaign_name | varchar | Campaign name |
| objective | varchar | Objective |
| account_id | varchar | Account identifier |
| publisher_platform | varchar | Publisher platform |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| spend | varchar | Spend |
| impressions | varchar | Impressions |
| clicks | varchar | Clicks |
| reach | varchar | Reach |
| frequency | varchar | Frequency |
| cpc | varchar | Cpc |
| cpm | varchar | Cpm |
| ctr | varchar | Ctr |
| outbound_clicks | varchar | Outbound clicks |
| outbound_clicks_ctr | varchar | Outbound clicks ctr |
| video_p25_watched | varchar | Video p25 watched |
| video_p50_watched | varchar | Video p50 watched |
| video_p75_watched | varchar | Video p75 watched |
| video_p100_watched | varchar | Video p100 watched |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (campaign_id, date_start, publisher_platform, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'meta_ads_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
