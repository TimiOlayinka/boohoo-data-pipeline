------------------------------------------------------------------------------------------------------------------------
-- odl.fact_ga4_sessions
-- GA4 web session fact with traffic source mapping and conversion metrics
-- Follows HnB fact_sessions_ga4 pattern
------------------------------------------------------------------------------------------------------------------------
SELECT
    MD5(s.session_id || '|' || s.brand)                 AS session_sk,
    s.session_id                                        AS session_nk,
    s.user_pseudo_id,
    s.date_nk,
    EXTRACT(YEAR FROM s.date_nk)                        AS year,
    EXTRACT(MONTH FROM s.date_nk)                       AS month,
    EXTRACT(DOW FROM s.date_nk)                         AS day_of_week,
    s.session_timestamp,
    s.source,
    s.medium,
    s.channel_group,
    s.utm_campaign,
    COALESCE(utm.traffic_source_l1, s.channel_group)    AS traffic_source_l1,
    COALESCE(utm.traffic_source_l2, s.source)           AS traffic_source_l2,
    s.device_category,
    s.country,
    s.landing_page,
    s.page_views,
    s.session_duration_seconds,
    s.is_bounced,
    s.is_engaged_session,
    s.is_new_user,
    s.transactions,
    s.revenue,
    s.add_to_carts,
    s.checkouts,
    s.brand,
    b.brand_tier,
    s.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM {{ ref('rdl_ga4_sessions') }} s
LEFT JOIN {{ ref('map_utm_sources') }} utm
    ON s.source = utm.utm_source AND s.medium = utm.utm_medium
LEFT JOIN {{ ref('map_brand') }} b
    ON s.brand = b.brand
