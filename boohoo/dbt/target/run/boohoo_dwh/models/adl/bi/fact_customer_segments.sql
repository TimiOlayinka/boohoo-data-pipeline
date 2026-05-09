
  
    

  create  table
    "boohoo_dwh"."bi"."fact_customer_segments__dbt_tmp"
    
    
    
  as (
    ------------------------------------------------------------------------------------------------------------------------
-- bi.fact_customer_segments
-- Customer segmentation analysis for CRM dashboards
------------------------------------------------------------------------------------------------------------------------
SELECT
    c.brand,
    b.brand_tier,
    c.customer_segment,
    c.gender,
    c.country,
    COUNT(*)                                                AS customer_count,
    COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)    AS opted_in_count,
    ROUND(COUNT(CASE WHEN c.is_marketing_opted_in THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1) AS opt_in_rate_pct,
    MIN(c.registration_date)                                AS earliest_registration,
    MAX(c.registration_date)                                AS latest_registration,
    c.ingest_date
FROM "boohoo_dwh"."odl"."dim_customers" c
LEFT JOIN "boohoo_dwh"."odl"."map_brand" b ON c.brand = b.brand
GROUP BY 1, 2, 3, 4, 5, 11
  );
  