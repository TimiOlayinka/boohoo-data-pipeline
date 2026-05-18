# dim_campaigns

## Purpose
Unified campaign dimension across all ad platforms (Meta, Google, TikTok)

## Grain
One row per (campaign_nk, platform, brand)

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| campaign_sk | varchar(200) | Campaign sk |
| campaign_nk | varchar(100) | Campaign nk |
| campaign_name | varchar | Campaign name |
| objective | varchar | Objective |
| platform | varchar | Platform |
| CASE | varchar | Case |
| WHEN campaign_name LIKE '%Branded%'     THEN 'Brand' | varchar | When campaign name like '%branded%'     then 'brand' |
| WHEN campaign_name LIKE '%Generic%'     THEN 'Generic' | varchar | When campaign name like '%generic%'     then 'generic' |
| WHEN campaign_name LIKE '%NonBranded%'  THEN 'Generic' | varchar | When campaign name like '%nonbranded%'  then 'generic' |
| WHEN campaign_name LIKE '%Shopping%'    THEN 'Shopping' | varchar | When campaign name like '%shopping%'    then 'shopping' |
| WHEN campaign_name LIKE '%PMax%'        THEN 'Performance Max' | varchar | When campaign name like '%pmax%'        then 'performance max' |
| WHEN campaign_name LIKE '%DPA%'         THEN 'Dynamic Product Ads' | varchar | When campaign name like '%dpa%'         then 'dynamic product ads' |
| WHEN campaign_name LIKE '%Retargeting%' THEN 'Retargeting' | varchar | When campaign name like '%retargeting%' then 'retargeting' |
| WHEN campaign_name LIKE '%Lookalike%'   THEN 'Prospecting' | varchar | When campaign name like '%lookalike%'   then 'prospecting' |
| WHEN campaign_name LIKE '%Prospecting%' THEN 'Prospecting' | varchar | When campaign name like '%prospecting%' then 'prospecting' |
| WHEN campaign_name LIKE '%Awareness%'   THEN 'Awareness' | varchar | When campaign name like '%awareness%'   then 'awareness' |
| WHEN campaign_name LIKE '%Video%'       THEN 'Video' | varchar | When campaign name like '%video%'       then 'video' |
| WHEN campaign_name LIKE '%DemandGen%'   THEN 'Demand Gen' | varchar | When campaign name like '%demandgen%'   then 'demand gen' |
| WHEN campaign_name LIKE '%Engagement%'  THEN 'Engagement' | varchar | When campaign name like '%engagement%'  then 'engagement' |
| WHEN campaign_name LIKE '%SparkAds%'    THEN 'Spark Ads' | varchar | When campaign name like '%sparkads%'    then 'spark ads' |
| WHEN campaign_name LIKE '%BlackFriday%' THEN 'Promotional' | varchar | When campaign name like '%blackfriday%' then 'promotional' |
| WHEN campaign_name LIKE '%Sale%'        THEN 'Promotional' | varchar | When campaign name like '%sale%'        then 'promotional' |
| WHEN campaign_name LIKE '%Payday%'      THEN 'Promotional' | varchar | When campaign name like '%payday%'      then 'promotional' |
| ELSE 'Other' | varchar | Else 'other' |
| campaign_type | varchar | Campaign type |
| brand | varchar | Boohoo Group brand name |
| dwh_created_at | varchar | Timestamp when this row was created in the warehouse |

## Key business rules
- Deduplicated by (campaign_nk, platform, brand), keeping latest version
- Unifies 3 brand-level models via UNION ALL
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Contains CASE WHEN classification logic (see SQL for detail)

## Upstream inputs
- `ref('rdl_meta_ads')`
- `ref('rdl_google_ads')`
- `ref('rdl_tiktok_ads')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
