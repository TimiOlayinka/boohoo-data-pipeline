# fact_tiktok_ad_insights

## Purpose
Unified TikTok Ads performance with surrogate keys

## Grain
One row per record in fact_tiktok_ad_insights

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand) | varchar | Brand) |
| tiktok_ad_sk | varchar(200) | Tiktok ad sk |
| tiktok_ad_nk | varchar(100) | Tiktok ad nk |
| tiktok_advertiser_id | varchar(100) | Tiktok Advertiser identifier |
| tiktok_campaign_name | varchar | Tiktok Campaign name |
| objective | varchar | Objective |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_tiktok_ads')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
