# fact_google_ads_performance

## Purpose
Unified Google Ads performance with channel grouping classification

## Grain
One row per record in fact_google_ads_performance

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| brand) | varchar | Brand) |
| google_ads_sk | varchar(200) | Google ads sk |
| google_ads_customer_nk | varchar(100) | Google ads customer nk |
| google_ads_campaign_nk | varchar(100) | Google ads campaign nk |
| google_ads_ad_group_nk | varchar(100) | Google ads ad group nk |
| google_ads_ad_nk | varchar(100) | Google ads ad nk |
| campaign_sk | varchar(200) | Campaign sk |
| google_ads_campaign_status | varchar | Google Ads Campaign status |
| channel_type | varchar | Channel type |
| channel_group | varchar | Channel group |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Contains CASE WHEN classification logic (see SQL for detail)
- LEFT JOIN to dim_campaigns for enrichment
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_google_ads')`
- `ref('dim_campaigns')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
