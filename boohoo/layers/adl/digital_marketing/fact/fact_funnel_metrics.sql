--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_funnel_metrics
-- Marketing funnel — Awareness → Consideration → Conversion
-- Links ad impressions → site sessions → add-to-cart → purchase by channel
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_funnel_metrics;

CREATE TABLE "adl_digital_marketing".fact_funnel_metrics
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
WITH ad_impressions AS (
    SELECT date_nk, brand, channel, channel_type,
           SUM(spend) AS spend, SUM(impressions) AS impressions, SUM(clicks) AS ad_clicks
    FROM "adl_digital_marketing".fact_campaign_spend_daily
    WHERE channel_type IN ('Paid Social', 'Paid Search')
    GROUP BY 1, 2, 3, 4
),
site_sessions AS (
    SELECT date_nk, brand,
           traffic_source_l2                            :: VARCHAR(50)  AS channel,
           traffic_source_l1                            :: VARCHAR(50)  AS channel_type,
           COUNT(*)                                     :: INT          AS sessions,
           SUM(CASE WHEN is_engaged_session THEN 1 ELSE 0 END) :: INT  AS engaged_sessions,
           SUM(add_to_carts)                            :: INT          AS add_to_carts,
           SUM(checkouts)                               :: INT          AS checkouts,
           SUM(transactions)                            :: INT          AS purchases,
           SUM(revenue)                                 :: DECIMAL(18,2) AS revenue
    FROM "dev_odl".fact_ga4_sessions
    WHERE traffic_source_l1 IN ('Paid Search', 'Paid Social', 'Paid Shopping')
    GROUP BY 1, 2, 3, 4
)
SELECT
    COALESCE(a.date_nk, s.date_nk)                     :: DATE         AS date_nk,
    EXTRACT(YEAR FROM COALESCE(a.date_nk, s.date_nk))  :: INT          AS year,
    EXTRACT(MONTH FROM COALESCE(a.date_nk, s.date_nk)) :: INT          AS month,
    COALESCE(a.brand, s.brand)                          :: VARCHAR(50)  AS brand,
    COALESCE(a.channel, s.channel)                      :: VARCHAR(50)  AS channel,
    COALESCE(a.channel_type, s.channel_type)            :: VARCHAR(50)  AS channel_type,
    -- Funnel stages
    COALESCE(a.impressions, 0)                          :: BIGINT       AS f1_impressions,
    COALESCE(a.ad_clicks, 0)                            :: BIGINT       AS f2_ad_clicks,
    COALESCE(s.sessions, 0)                             :: INT          AS f3_sessions,
    COALESCE(s.engaged_sessions, 0)                     :: INT          AS f4_engaged_sessions,
    COALESCE(s.add_to_carts, 0)                         :: INT          AS f5_add_to_carts,
    COALESCE(s.checkouts, 0)                            :: INT          AS f6_checkouts,
    COALESCE(s.purchases, 0)                            :: INT          AS f7_purchases,
    COALESCE(s.revenue, 0)                              :: DECIMAL(18,2) AS f8_revenue,
    COALESCE(a.spend, 0)                                :: DECIMAL(18,4) AS spend,
    -- Funnel conversion rates
    ROUND(COALESCE(a.ad_clicks, 0)::FLOAT / NULLIF(a.impressions, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS click_through_rate,
    ROUND(COALESCE(s.sessions, 0)::FLOAT / NULLIF(a.ad_clicks, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS click_to_session_rate,
    ROUND(COALESCE(s.add_to_carts, 0)::FLOAT / NULLIF(s.sessions, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS session_to_cart_rate,
    ROUND(COALESCE(s.checkouts, 0)::FLOAT / NULLIF(s.add_to_carts, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS cart_to_checkout_rate,
    ROUND(COALESCE(s.purchases, 0)::FLOAT / NULLIF(s.checkouts, 0) * 100, 2)
                                                        :: DECIMAL(18,2) AS checkout_to_purchase_rate,
    ROUND(COALESCE(s.purchases, 0)::FLOAT / NULLIF(a.impressions, 0) * 100, 4)
                                                        :: DECIMAL(18,4) AS overall_conversion_rate

FROM ad_impressions a
FULL OUTER JOIN site_sessions s
    ON a.date_nk = s.date_nk AND a.brand = s.brand AND a.channel = s.channel
;

COMMIT TRANSACTION;
