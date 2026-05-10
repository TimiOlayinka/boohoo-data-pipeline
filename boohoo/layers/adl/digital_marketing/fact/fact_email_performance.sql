--@variable "adl_digital_marketing" ${SCHEMA_ADL_DIGITAL_MARKETING}

------------------------------------------------------------------------------------------------------------------------
-- fact_email_performance
-- Email/CRM marketing dashboard — campaign type performance and health metrics
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "adl_digital_marketing".fact_email_performance;

CREATE TABLE "adl_digital_marketing".fact_email_performance
DISTSTYLE KEY DISTKEY (brand)
SORTKEY (date_nk)
AS
SELECT
    date_nk                                             :: DATE             AS date_nk,
    EXTRACT(YEAR FROM date_nk)                          :: INT              AS year,
    EXTRACT(MONTH FROM date_nk)                         :: INT              AS month,
    brand                                               :: VARCHAR(50)      AS brand,
    brand_tier                                          :: VARCHAR(10)      AS brand_tier,
    campaign_type                                       :: VARCHAR(50)      AS campaign_type,
    campaign_name                                       :: VARCHAR(500)     AS campaign_name,
    subject_line                                        :: VARCHAR(1000)    AS subject_line,
    -- Volume metrics
    list_size                                           :: INT              AS list_size,
    delivered                                           :: INT              AS delivered,
    opened                                              :: INT              AS opened,
    unique_opens                                        :: INT              AS unique_opens,
    clicked                                             :: INT              AS clicked,
    unique_clicks                                       :: INT              AS unique_clicks,
    unsubscribed                                        :: INT              AS unsubscribed,
    bounced                                             :: INT              AS bounced,
    spam_complaints                                     :: INT              AS spam_complaints,
    converted                                           :: INT              AS converted,
    revenue                                             :: DECIMAL(18,2)    AS revenue,
    -- Rate metrics
    delivery_rate                                       :: DECIMAL(8,2)     AS delivery_rate,
    open_rate                                           :: DECIMAL(8,2)     AS open_rate,
    click_rate                                          :: DECIMAL(8,2)     AS click_rate,
    click_to_open_rate                                  :: DECIMAL(8,2)     AS click_to_open_rate,
    conversion_rate                                     :: DECIMAL(8,2)     AS conversion_rate,
    revenue_per_email                                   :: DECIMAL(10,4)    AS revenue_per_email,
    -- Derived health metrics
    ROUND(unsubscribed::FLOAT / NULLIF(delivered, 0) * 100, 4)
                                                        :: DECIMAL(8,4)     AS unsubscribe_rate,
    ROUND(bounced::FLOAT / NULLIF(list_size, 0) * 100, 4)
                                                        :: DECIMAL(8,4)     AS bounce_rate,
    ROUND(spam_complaints::FLOAT / NULLIF(delivered, 0) * 100, 4)
                                                        :: DECIMAL(8,4)     AS spam_rate,
    -- Revenue attribution
    ROUND(revenue / NULLIF(converted, 0), 2)            :: DECIMAL(18,2)    AS avg_order_value,
    ROUND(revenue / NULLIF(clicked, 0), 2)              :: DECIMAL(18,2)    AS revenue_per_click
FROM "dev_odl".fact_email_engagement
;

COMMIT TRANSACTION;
