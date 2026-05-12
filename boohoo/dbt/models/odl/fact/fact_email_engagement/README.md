# fact_email_engagement

## Purpose
Email campaign engagement fact table with delivery and conversion metrics

## Grain
One row per record in fact_email_engagement

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand) | varchar | Brand) |
| email_engagement_sk | varchar(200) | Email engagement sk |
| campaign_nk | varchar(100) | Campaign nk |
| campaign_name | varchar | Campaign name |
| campaign_type | varchar | Campaign type |
| subject_line | varchar | Subject line |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_email_campaigns')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
