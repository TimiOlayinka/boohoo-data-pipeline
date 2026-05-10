------------------------------------------------------------------------------------------------------------------------
-- odl.dim_campaigns
-- Unified campaign dimension across all ad platforms (Meta, Google, TikTok)
-- Follows HnB dim_campaigns pattern with surrogate keys
------------------------------------------------------------------------------------------------------------------------
WITH meta_campaigns AS (
    SELECT DISTINCT
        campaign_id                                     AS campaign_nk,
        campaign_name,
        objective,
        'Meta Ads'                                      AS platform,
        brand
    FROM {{ ref('rdl_meta_ads') }}
),
google_campaigns AS (
    SELECT DISTINCT
        campaign_id                                     AS campaign_nk,
        campaign_name,
        channel_type                                    AS objective,
        'Google Ads'                                    AS platform,
        brand
    FROM {{ ref('rdl_google_ads') }}
),
tiktok_campaigns AS (
    SELECT DISTINCT
        SPLIT_PART(ad_id, '-', 1) || '-' || SPLIT_PART(ad_id, '-', 2) || '-' || SPLIT_PART(ad_id, '-', 3)
                                                        AS campaign_nk,
        campaign_name,
        objective,
        'TikTok Ads'                                    AS platform,
        brand
    FROM {{ ref('rdl_tiktok_ads') }}
),
all_campaigns AS (
    SELECT * FROM meta_campaigns
    UNION ALL
    SELECT * FROM google_campaigns
    UNION ALL
    SELECT * FROM tiktok_campaigns
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY campaign_nk, platform, brand ORDER BY campaign_name
    ) AS rnk
    FROM all_campaigns
)
SELECT
    MD5(campaign_nk || '|' || platform || '|' || brand) AS campaign_sk,
    campaign_nk,
    campaign_name,
    objective,
    platform,
    -- Campaign name classification (inspired by HnB's classified CTE)
    CASE
        WHEN campaign_name LIKE '%Branded%'     THEN 'Brand'
        WHEN campaign_name LIKE '%Generic%'     THEN 'Generic'
        WHEN campaign_name LIKE '%NonBranded%'  THEN 'Generic'
        WHEN campaign_name LIKE '%Shopping%'    THEN 'Shopping'
        WHEN campaign_name LIKE '%PMax%'        THEN 'Performance Max'
        WHEN campaign_name LIKE '%DPA%'         THEN 'Dynamic Product Ads'
        WHEN campaign_name LIKE '%Retargeting%' THEN 'Retargeting'
        WHEN campaign_name LIKE '%Lookalike%'   THEN 'Prospecting'
        WHEN campaign_name LIKE '%Prospecting%' THEN 'Prospecting'
        WHEN campaign_name LIKE '%Awareness%'   THEN 'Awareness'
        WHEN campaign_name LIKE '%Video%'       THEN 'Video'
        WHEN campaign_name LIKE '%DemandGen%'   THEN 'Demand Gen'
        WHEN campaign_name LIKE '%Engagement%'  THEN 'Engagement'
        WHEN campaign_name LIKE '%SparkAds%'    THEN 'Spark Ads'
        WHEN campaign_name LIKE '%BlackFriday%' THEN 'Promotional'
        WHEN campaign_name LIKE '%Sale%'        THEN 'Promotional'
        WHEN campaign_name LIKE '%Payday%'      THEN 'Promotional'
        ELSE 'Other'
    END                                                 AS campaign_type,
    brand,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM dedup WHERE rnk = 1
