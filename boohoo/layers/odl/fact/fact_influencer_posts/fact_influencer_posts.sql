--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_influencer_posts
-- Influencer post performance fact table with engagement and ROI metrics
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_influencer_posts;

CREATE TABLE "dev_odl".fact_influencer_posts
DISTSTYLE KEY DISTKEY (post_nk)
SORTKEY (date_nk)
AS
SELECT
    MD5(p.post_id || '|' || p.brand)                    :: VARCHAR(32)      AS influencer_sk,
    p.post_id                                           :: VARCHAR(50)      AS post_nk,
    p.creator_handle,
    p.creator_name,
    p.creator_tier,
    p.creator_followers,
    p.platform,
    p.content_type,
    p.date_nk,
    EXTRACT(YEAR FROM p.date_nk)                        :: INT              AS year,
    EXTRACT(MONTH FROM p.date_nk)                       :: INT              AS month,
    p.post_url,
    p.category_promoted,
    p.promo_code,
    p.cost,
    p.reach,
    p.impressions,
    p.likes,
    p.comments,
    p.shares,
    p.saves,
    p.total_engagement,
    p.engagement_rate,
    p.link_clicks,
    p.conversions,
    p.revenue_attributed,
    p.emv,
    -- Calculated ROI metrics
    ROUND(p.cost / NULLIF(p.total_engagement, 0), 4)    :: DECIMAL(18,4)    AS cost_per_engagement,
    ROUND(p.cost / NULLIF(p.link_clicks, 0), 2)         :: DECIMAL(18,2)    AS cost_per_click,
    ROUND(p.cost / NULLIF(p.conversions, 0), 2)         :: DECIMAL(18,2)    AS cost_per_conversion,
    ROUND(p.revenue_attributed / NULLIF(p.cost, 0), 2)  :: DECIMAL(18,2)    AS roi,
    ROUND(p.emv / NULLIF(p.cost, 0), 2)                 :: DECIMAL(18,2)    AS emv_ratio,
    p.brand,
    mb.brand_tier,
    p.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM "rdl_creatoriq".influencer_posts p
LEFT JOIN "dev_odl".map_brand mb
    ON p.brand = mb.brand
;

COMMIT TRANSACTION;
