--@variable "rdl_shopify" ${SCHEMA_RDL_SHOPIFY}

------------------------------------------------------------------------------------------------------------------------
-- nastygal_products
-- Deduplicated NastyGal products from nastygal_products_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_shopify".nastygal_products;

CREATE TABLE "rdl_shopify".nastygal_products
DISTSTYLE KEY DISTKEY (product_id)
SORTKEY (product_id)
AS
WITH history AS (
    SELECT variant_id AS product_id, title AS product_name, option1 AS colour, product_type AS category,
           tags AS subcategory, price AS current_price, cost AS cost_price,
           rrp, vendor AS material, created_at AS season, is_active, stock_status,
           created_at, updated_at,
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_shopify".nastygal_products_history
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY product_id ORDER BY ingest_date DESC, ingest_ts DESC
    ) AS rnk
    FROM history
)
SELECT
    product_id                                      :: VARCHAR(50)      AS product_id,
    product_name                                    :: VARCHAR(500)     AS product_name,
    colour                                          :: VARCHAR(100)     AS colour,
    category                                        :: VARCHAR(100)     AS category,
    subcategory                                     :: VARCHAR(100)     AS subcategory,
    current_price                                   :: DECIMAL(18,2)    AS current_price,
    cost_price                                      :: DECIMAL(18,2)    AS cost_price,
    rrp                                             :: DECIMAL(18,2)    AS rrp,
    material                                        :: VARCHAR(100)     AS material,
    season                                          :: VARCHAR(50)      AS season,
    is_active::BOOLEAN                                                  AS is_active,
    stock_status                                    :: VARCHAR(50)      AS stock_status,
    created_at::TIMESTAMP                                               AS created_at,
    updated_at::TIMESTAMP                                               AS updated_at,
    'NastyGal'                                      :: VARCHAR(50)      AS brand,
    'shopify'                                       :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
