# fact_campaign_performance

## Purpose
Campaign-level deep-dive — top/bottom campaigns by spend, ROAS, conversions

## Grain
One row per record in fact_campaign_performance

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Unifies 3 brand-level models via UNION ALL

## Upstream inputs
- `ref('fact_meta_campaign_insights')`
- `ref('fact_google_ads_performance')`
- `ref('fact_tiktok_ad_insights')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
