# rdl_influencer_posts

## Purpose
Rdl Influencer Posts — RDL layer model

## Grain
One row per (post_id, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| post_id | varchar | Post identifier |
| creator_handle | varchar | Creator handle |
| creator_name | varchar | Creator name |
| creator_tier | varchar | Creator tier |
| creator_followers | varchar | Creator followers |
| platform | varchar | Platform |
| content_type | varchar | Content type |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| post_url | varchar | Post url |
| category_promoted | varchar | Category promoted |
| promo_code | varchar | Promo code |
| tracking_url | varchar | Tracking url |
| cost | varchar | Cost |
| reach | varchar | Reach |
| impressions | varchar | Impressions |
| likes | varchar | Likes |
| comments | varchar | Comments |
| shares | varchar | Shares |
| saves | varchar | Saves |
| total_engagement | varchar | Total engagement |
| engagement_rate | varchar | Engagement rate |
| link_clicks | varchar | Link clicks |
| conversions | varchar | Conversions |
| revenue_attributed | varchar | Revenue attributed |
| emv | varchar | Emv |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (post_id, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'influencer_posts_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
