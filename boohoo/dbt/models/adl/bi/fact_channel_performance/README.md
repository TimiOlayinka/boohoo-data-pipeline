# fact_channel_performance

## Purpose
Cross-channel benchmarking — normalised metrics across all marketing channels

## Grain
One row per record in fact_channel_performance

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Unifies 6 brand-level models via UNION ALL

## Upstream inputs
- `ref('fact_meta_campaign_insights')`
- `ref('fact_google_ads_performance')`
- `ref('fact_tiktok_ad_insights')`
- `ref('fact_email_engagement')`
- `ref('fact_influencer_performance')`
- `ref('fact_ga4_sessions')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
