
  
    

  create  table
    "boohoo_dwh"."odl"."dim_customers__dbt_tmp"
    
    
    
  as (
    ------------------------------------------------------------------------------------------------------------------------
-- odl.dim_customers
-- Unified customer dimension across all Boohoo Group brands (star schema)
------------------------------------------------------------------------------------------------------------------------
WITH all_customers AS (
SELECT * FROM "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_boohoo_commerce"."boohoo_man_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_salesforce_commerce"."plt_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_shopify"."nastygal_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_magento"."karen_millen_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_magento"."coast_customers"
UNION ALL
SELECT * FROM "boohoo_dwh"."rdl_oracle_commerce"."debenhams_customers"
),
dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY email ORDER BY registration_date DESC, ingest_date DESC
    ) AS rnk
    FROM all_customers
)
SELECT
    MD5(customer_id || '|' || brand) AS customer_sk,
    customer_id                      AS customer_nk,
    email,
    first_name,
    last_name,
    phone,
    city,
    country,
    customer_segment,
    registration_date,
    gender,
    is_marketing_opted_in,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP AS dwh_created_at
FROM dedup WHERE rnk = 1
  );
  