------------------------------------------------------------------------------------------------------------------------
-- odl.fact_email_engagement
-- Email campaign engagement fact table with delivery and conversion metrics
-- Follows HnB fact_email_engagement pattern
------------------------------------------------------------------------------------------------------------------------
SELECT
    MD5(e.campaign_id || '|' || e.date_nk || '|' || e.brand)
        AS email_engagement_sk,
    e.campaign_id                                       AS campaign_nk,
    e.campaign_name,
    e.campaign_type,
    e.subject_line,
    e.date_nk,
    EXTRACT(YEAR FROM e.date_nk)                        AS year,
    EXTRACT(MONTH FROM e.date_nk)                       AS month,
    e.send_timestamp,
    e.list_size,
    e.delivered,
    e.opened,
    e.unique_opens,
    e.clicked,
    e.unique_clicks,
    e.unsubscribed,
    e.bounced,
    e.spam_complaints,
    e.converted,
    e.revenue,
    -- Calculated rates (in case source rates are stale after dedup)
    ROUND(e.delivered::FLOAT / NULLIF(e.list_size, 0) * 100, 2)     AS delivery_rate,
    e.open_rate,
    e.click_rate,
    e.click_to_open_rate,
    e.conversion_rate,
    e.revenue_per_email,
    e.brand,
    b.brand_tier,
    e.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at
FROM {{ ref('rdl_email_campaigns') }} e
LEFT JOIN {{ ref('map_brand') }} b
    ON e.brand = b.brand
