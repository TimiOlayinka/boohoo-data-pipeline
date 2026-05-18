# fact_ga4_sessions

## Purpose
GA4 web session fact with traffic source mapping and conversion metrics

## Grain
One row per record in fact_ga4_sessions

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| session_sk | varchar(200) | Session sk |
| session_nk | varchar(100) | Session nk |
| user_pseudo_id | varchar(100) | User Pseudo identifier |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- LEFT JOIN to map_utm_sources for enrichment
- LEFT JOIN to map_brand for enrichment

## Upstream inputs
- `ref('rdl_ga4_sessions')`
- `ref('map_utm_sources')`
- `ref('map_brand')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
