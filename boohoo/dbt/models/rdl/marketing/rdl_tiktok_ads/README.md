# rdl_tiktok_ads

## Purpose
Rdl Tiktok Ads — RDL layer model

## Grain
One row per (ad_id, stat_time_day, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| advertiser_id | varchar | Advertiser identifier |
| ad_id | varchar | Ad identifier |
| campaign_name | varchar | Campaign name |
| objective | varchar | Objective |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| spend | varchar | Spend |
| impressions | varchar | Impressions |
| clicks | varchar | Clicks |
| reach | varchar | Reach |
| frequency | varchar | Frequency |
| ctr | varchar | Ctr |
| cpc | varchar | Cpc |
| cpm | varchar | Cpm |
| conversion_rate | varchar | Conversion rate |
| conversion | varchar | Conversion |
| cost_per_conversion | varchar | Cost per conversion |
| purchase | varchar | Purchase |
| video_play_actions | varchar | Video play actions |
| video_watched_2s | varchar | Video watched 2s |
| video_watched_6s | varchar | Video watched 6s |
| video_views_p25 | varchar | Video views p25 |
| video_views_p50 | varchar | Video views p50 |
| video_views_p75 | varchar | Video views p75 |
| video_views_p100 | varchar | Video views p100 |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (ad_id, stat_time_day, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'tiktok_ads_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
