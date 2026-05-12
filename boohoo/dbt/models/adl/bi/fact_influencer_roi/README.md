# fact_influencer_roi

## Purpose
Influencer marketing ROI dashboard — creator performance by tier, platform, brand

## Grain
One row per record in fact_influencer_roi

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Standard pass-through

## Upstream inputs
- `ref('fact_influencer_performance')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
