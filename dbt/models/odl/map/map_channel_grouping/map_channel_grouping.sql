------------------------------------------------------------------------------------------------------------------------
-- odl.map_channel_grouping
-- Maps Google Ads channel_type + campaign_name → channel_group
-- Inspired by HnB's classified CTE in fact_google_ads_standard_campaign_performance.sql
------------------------------------------------------------------------------------------------------------------------
SELECT
    'SEARCH'          AS channel_type,
    '%Branded%'   AS campaign_pattern,
    'Branded Search'  AS channel_group
UNION ALL SELECT
    'SEARCH',
    '%Generic%',
    'Generic Search'
UNION ALL SELECT
    'SEARCH',
    '%NonBranded%',
    'Generic Search'
UNION ALL SELECT
    'SEARCH',
    '%Competitor%',
    'Competitor Search'
UNION ALL SELECT
    'SHOPPING',
    '%Standard%',
    'Shopping'
UNION ALL SELECT
    'SHOPPING',
    '%Smart%',
    'Smart Shopping'
UNION ALL SELECT
    'PERFORMANCE_MAX',
    '%PMax%',
    'Performance Max'
UNION ALL SELECT
    'DEMAND_GEN',
    '%DemandGen%',
    'Demand Gen'
UNION ALL SELECT
    'VIDEO',
    '%Video%',
    'Video / YouTube'
UNION ALL SELECT
    'VIDEO',
    '%YT%',
    'Video / YouTube'
