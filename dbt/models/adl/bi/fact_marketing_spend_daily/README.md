# fact_marketing_spend_daily

## Purpose
Daily marketing spend overview — spend + performance by brand × channel

## Grain
One row per (brand, channel)

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Unifies 5 brand-level models via UNION ALL

## Upstream inputs
- `ref('fact_meta_campaign_insights')`
- `ref('fact_google_ads_performance')`
- `ref('fact_tiktok_ad_insights')`
- `ref('fact_email_engagement')`
- `ref('fact_influencer_performance')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
