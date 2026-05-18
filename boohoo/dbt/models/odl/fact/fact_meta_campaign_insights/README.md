# fact_meta_campaign_insights

## Purpose
Unified Meta Ads campaign insights with surrogate keys

## Grain
One row per record in fact_meta_campaign_insights

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand) | varchar | Brand) |
| meta_insight_sk | varchar(200) | Meta insight sk |
| meta_campaign_nk | varchar(100) | Meta campaign nk |
| meta_campaign_name | varchar | Meta Campaign name |
| campaign_sk | varchar(200) | Campaign sk |
| campaign_type | varchar | Campaign type |
| objective | varchar | Objective |
| publisher_platform | varchar | Publisher platform |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- LEFT JOIN to dim_campaigns for enrichment
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_meta_ads')`
- `ref('dim_campaigns')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
