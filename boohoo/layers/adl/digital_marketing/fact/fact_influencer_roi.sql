--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_influencer_roi
-- Influencer marketing ROI dashboard — creator performance by tier, platform, brand
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_influencer_roi;

CREATE TABLE "adl_digital_marketing".fact_influencer_roi
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
SELECT
    date_nk                                             :: DATE             AS date_nk,
    EXTRACT(YEAR FROM date_nk)                          :: INT              AS year,
    EXTRACT(MONTH FROM date_nk)                         :: INT              AS month,
    brand                                               :: VARCHAR(50)      AS brand,
    brand_tier                                          :: VARCHAR(10)      AS brand_tier,
    creator_handle                                      :: VARCHAR(200)     AS creator_handle,
    creator_name                                        :: VARCHAR(200)     AS creator_name,
    creator_tier                                        :: VARCHAR(20)      AS creator_tier,
    creator_followers                                   :: BIGINT           AS creator_followers,
    platform                                            :: VARCHAR(50)      AS platform,
    content_type                                        :: VARCHAR(50)      AS content_type,
    category_promoted                                   :: VARCHAR(100)     AS category_promoted,
    promo_code                                          :: VARCHAR(50)      AS promo_code,
    cost                                                :: DECIMAL(18,2)    AS cost,
    reach                                               :: BIGINT           AS reach,
    impressions                                         :: BIGINT           AS impressions,
    likes                                               :: BIGINT           AS likes,
    comments                                            :: BIGINT           AS comments,
    shares                                              :: BIGINT           AS shares,
    saves                                               :: BIGINT           AS saves,
    total_engagement                                    :: BIGINT           AS total_engagement,
    engagement_rate                                     :: DECIMAL(8,4)     AS engagement_rate,
    link_clicks                                         :: BIGINT           AS link_clicks,
    conversions                                         :: BIGINT           AS conversions,
    revenue_attributed                                  :: DECIMAL(18,2)    AS revenue_attributed,
    cost_per_engagement                                 :: DECIMAL(18,4)    AS cost_per_engagement,
    cost_per_click                                      :: DECIMAL(18,2)    AS cost_per_click,
    cost_per_conversion                                 :: DECIMAL(18,2)    AS cost_per_conversion,
    roi                                                 :: DECIMAL(18,2)    AS roi,
    emv                                                 :: DECIMAL(18,2)    AS emv,
    emv_ratio                                           :: DECIMAL(18,2)    AS emv_ratio,
    ROUND(total_engagement::FLOAT / NULLIF(creator_followers, 0) * 100, 2)
                                                        :: DECIMAL(8,2)     AS follower_engagement_rate,
    ROUND(revenue_attributed / NULLIF(reach, 0) * 1000, 2)
                                                        :: DECIMAL(18,2)    AS revenue_per_1k_reach,
    ROUND(link_clicks::FLOAT / NULLIF(impressions, 0) * 100, 2)
                                                        :: DECIMAL(8,2)     AS link_click_rate
FROM "dev_odl".fact_influencer_posts
;

COMMIT TRANSACTION;
