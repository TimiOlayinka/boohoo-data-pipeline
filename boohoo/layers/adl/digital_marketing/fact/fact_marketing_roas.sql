--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_marketing_roas
-- Return on Ad Spend — links ad spend to GA4 revenue for attribution analysis
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_marketing_roas;

CREATE TABLE "adl_digital_marketing".fact_marketing_roas
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
WITH paid_spend AS (
    SELECT
        date_nk, brand, channel, channel_type, brand_tier,
        SUM(spend) AS spend, SUM(clicks) AS clicks
    FROM "adl_digital_marketing".fact_campaign_spend_daily
    WHERE channel_type IN ('Paid Social', 'Paid Search')
    GROUP BY 1, 2, 3, 4, 5
),
ga4_revenue AS (
    SELECT
        date_nk, brand,
        traffic_source_l2                               :: VARCHAR(50)      AS channel,
        traffic_source_l1                               :: VARCHAR(50)      AS channel_type,
        SUM(revenue)                                    :: DECIMAL(18,2)    AS revenue_attributed,
        SUM(transactions)                               :: INT              AS orders,
        COUNT(DISTINCT session_nk)                      :: INT              AS sessions,
        COUNT(DISTINCT CASE WHEN transactions > 0 THEN session_nk END)
                                                        :: INT              AS converting_sessions
    FROM "dev_odl".fact_ga4_sessions
    WHERE traffic_source_l1 IN ('Paid Search', 'Paid Social', 'Paid Shopping')
    GROUP BY 1, 2, 3, 4
)
SELECT
    COALESCE(s.date_nk, r.date_nk)                     :: DATE             AS date_nk,
    EXTRACT(YEAR FROM COALESCE(s.date_nk, r.date_nk))  :: INT              AS year,
    EXTRACT(MONTH FROM COALESCE(s.date_nk, r.date_nk)) :: INT              AS month,
    COALESCE(s.brand, r.brand)                          :: VARCHAR(50)      AS brand,
    COALESCE(s.brand_tier, '')                          :: VARCHAR(10)      AS brand_tier,
    COALESCE(s.channel, r.channel)                      :: VARCHAR(50)      AS channel,
    COALESCE(s.channel_type, r.channel_type)            :: VARCHAR(50)      AS channel_type,
    COALESCE(s.spend, 0)                                :: DECIMAL(18,2)    AS spend,
    COALESCE(s.clicks, 0)                               :: BIGINT           AS ad_clicks,
    COALESCE(r.sessions, 0)                             :: INT              AS sessions,
    COALESCE(r.revenue_attributed, 0)                   :: DECIMAL(18,2)    AS revenue_attributed,
    COALESCE(r.orders, 0)                               :: INT              AS orders,
    COALESCE(r.converting_sessions, 0)                  :: INT              AS converting_sessions,
    -- ROAS metrics
    ROUND(COALESCE(r.revenue_attributed, 0) / NULLIF(s.spend, 0), 2)
                                                        :: DECIMAL(18,2)    AS roas,
    ROUND(s.spend / NULLIF(r.orders, 0), 2)             :: DECIMAL(18,2)    AS cost_per_acquisition,
    ROUND(s.spend / NULLIF(s.clicks, 0), 2)             :: DECIMAL(18,2)    AS cost_per_click,
    ROUND(r.revenue_attributed / NULLIF(r.orders, 0), 2)
                                                        :: DECIMAL(18,2)    AS avg_order_value,
    ROUND(r.converting_sessions::FLOAT / NULLIF(r.sessions, 0) * 100, 2)
                                                        :: DECIMAL(18,2)    AS session_conversion_rate

FROM paid_spend s
FULL OUTER JOIN ga4_revenue r
    ON s.date_nk = r.date_nk AND s.brand = r.brand AND s.channel = r.channel
;

COMMIT TRANSACTION;
