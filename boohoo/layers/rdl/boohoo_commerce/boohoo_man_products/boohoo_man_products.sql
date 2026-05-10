--@variable "rdl_boohoo_commerce" ${SCHEMA_RDL_BOOHOO_COMMERCE}

------------------------------------------------------------------------------------------------------------------------
-- boohoo_man_products
-- Deduplicated Boohoo Man products from boohoo_man_products_history
------------------------------------------------------------------------------------------------------------------------

SET enable_case_sensitive_identifier TO FALSE;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS "rdl_boohoo_commerce".boohoo_man_products;

CREATE TABLE "rdl_boohoo_commerce".boohoo_man_products
DISTSTYLE KEY DISTKEY (product_id)
SORTKEY (product_id)
AS
WITH history AS (
    SELECT sku AS product_id, data."product_name", data."colour", data."department" AS category,
           data."product_type" AS subcategory, data."selling_price" AS current_price, data."cost_price",
           data."rrp", data."material", data."season_code" AS season, data."is_active", data."stock_status",
           data."created_at", data."updated_at",
           ingest_date, REPLACE(SPLIT_PART(ingest_time, '+', 1), 'T', ' ')::TIMESTAMP AS ingest_ts
    FROM "rdl_boohoo_commerce".boohoo_man_products_history
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
    'Boohoo Man'                                    :: VARCHAR(50)      AS brand,
    'boohoo_commerce'                               :: VARCHAR(50)      AS source_system,
    ingest_date, ingest_ts
FROM dedup WHERE rnk = 1
;

COMMIT TRANSACTION;
