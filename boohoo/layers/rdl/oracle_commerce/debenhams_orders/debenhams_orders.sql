--@variable "rdl_oracle_commerce" ${SCHEMA_RDL_ORACLE_COMMERCE}

------------------------------------------------------------------------------------------------------------------------
-- debenhams_orders
-- Deduplicated Debenhams orders from debenhams_orders_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_oracle_commerce".debenhams_orders;

CREATE TABLE "rdl_oracle_commerce".debenhams_orders
DISTSTYLE KEY DISTKEY (order_id)
SORTKEY (order_timestamp)
AS
WITH history AS (
    SELECT order_number AS order_id, profile_id AS customer_id, submitted_date AS order_timestamp,
           price_total AS total_amount, state AS status, payment_type AS payment_method,
           discount_amount, shipping_cost, item_count, promotion_code AS promo_code, shipping_method AS delivery_method, site_code AS fulfilment_centre,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_oracle_commerce".debenhams_orders_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY order_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    order_id                                        :: VARCHAR(50)      AS order_id,
    customer_id                                     :: VARCHAR(50)      AS customer_id,
    order_timestamp::TIMESTAMP                                          AS order_timestamp,
    total_amount                                    :: DECIMAL(18,2)    AS total_amount,
    status                                          :: VARCHAR(50)      AS status,
    payment_method                                  :: VARCHAR(50)      AS payment_method,
    discount_amount                                 :: DECIMAL(18,2)    AS discount_amount,
    shipping_cost                                   :: DECIMAL(18,2)    AS shipping_cost,
    item_count                                      :: INT              AS item_count,
    promo_code                                      :: VARCHAR(50)      AS promo_code,
    delivery_method                                 :: VARCHAR(50)      AS delivery_method,
    fulfilment_centre                               :: VARCHAR(50)      AS fulfilment_centre,
    'Debenhams'                                     :: VARCHAR(50)      AS brand,
    'oracle_commerce'                               :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
