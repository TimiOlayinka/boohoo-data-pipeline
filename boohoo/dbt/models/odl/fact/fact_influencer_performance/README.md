# fact_influencer_performance

## Purpose
Influencer post performance fact table with engagement and ROI metrics

## Grain
One row per record in fact_influencer_performance

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| influencer_sk | varchar(200) | Influencer sk |
| post_nk | varchar(100) | Post nk |
| creator_handle | varchar | Creator handle |
| creator_name | varchar | Creator name |
| creator_tier | varchar | Creator tier |
| creator_followers | varchar | Creator followers |
| platform | varchar | Platform |
| content_type | varchar | Content type |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_influencer_posts')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
