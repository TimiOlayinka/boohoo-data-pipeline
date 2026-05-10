--@variable "dev_odl" ${SCHEMA_ODL}

------------------------------------------------------------------------------------------------------------------------
-- fact_ga4_sessions
-- GA4 web session fact with traffic source mapping and conversion metrics
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "dev_odl".fact_ga4_sessions;

CREATE TABLE "dev_odl".fact_ga4_sessions
DISTSTYLE KEY DISTKEY (session_nk)
SORTKEY (date_nk)
AS
SELECT
    MD5(s.session_id || '|' || s.brand)                 :: VARCHAR(32)      AS session_sk,
    s.session_id                                        :: VARCHAR(100)     AS session_nk,
    s.user_pseudo_id                                    :: VARCHAR(100)     AS user_pseudo_id,
    s.date_nk,
    EXTRACT(YEAR FROM s.date_nk)                        :: INT              AS year,
    EXTRACT(MONTH FROM s.date_nk)                       :: INT              AS month,
    EXTRACT(DOW FROM s.date_nk)                         :: INT              AS day_of_week,
    s.session_timestamp,
    s.source,
    s.medium,
    s.channel_group,
    s.utm_campaign,
    COALESCE(utm.traffic_source_l1, s.channel_group)    :: VARCHAR(50)      AS traffic_source_l1,
    COALESCE(utm.traffic_source_l2, s.source)           :: VARCHAR(50)      AS traffic_source_l2,
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
    mb.brand_tier,
    s.ingest_date,
    CURRENT_TIMESTAMP                                   AS dwh_created_at

FROM "rdl_ga".ga4_sessions s
LEFT JOIN "dev_odl".map_utm_sources utm
    ON s.source = utm.utm_source AND s.medium = utm.utm_medium
LEFT JOIN "dev_odl".map_brand mb
    ON s.brand = mb.brand
;

COMMIT TRANSACTION;
