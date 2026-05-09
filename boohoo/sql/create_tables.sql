-- ============================================================================
-- Data Architecture Portfolio — Table DDL
-- ============================================================================
-- Target: Amazon Redshift Serverless
-- Database: portfolio_db
--
-- Tables:
--   dim_customers     — Customer dimension (DISTSTYLE ALL)
--   dim_products      — Product dimension (DISTSTYLE ALL)
--   fact_orders       — Order facts (DISTKEY: customer_id)
--   fact_order_items   — Order line items (DISTKEY: order_id)
-- ============================================================================

-- ============================================================================
-- DIMENSION: Customers
-- ============================================================================
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id     VARCHAR(20)     NOT NULL    ENCODE zstd,
    first_name      VARCHAR(50)     NOT NULL    ENCODE zstd,
    last_name       VARCHAR(50)     NOT NULL    ENCODE zstd,
    email           VARCHAR(100)    NOT NULL    ENCODE zstd,
    city            VARCHAR(50)     NOT NULL    ENCODE zstd,
    country         VARCHAR(50)     NOT NULL    ENCODE zstd,
    segment         VARCHAR(20)     NOT NULL    ENCODE zstd,
    signup_date     DATE            NOT NULL    ENCODE az64,
    PRIMARY KEY (customer_id)
)
DISTSTYLE ALL
SORTKEY (signup_date);


-- ============================================================================
-- DIMENSION: Products
-- ============================================================================
CREATE TABLE IF NOT EXISTS dim_products (
    product_id      VARCHAR(20)     NOT NULL    ENCODE zstd,
    product_name    VARCHAR(100)    NOT NULL    ENCODE zstd,
    category        VARCHAR(50)     NOT NULL    ENCODE zstd,
    subcategory     VARCHAR(50)     NOT NULL    ENCODE zstd,
    unit_price      DECIMAL(10,2)   NOT NULL    ENCODE az64,
    cost_price      DECIMAL(10,2)   NOT NULL    ENCODE az64,
    is_active       BOOLEAN         NOT NULL    DEFAULT TRUE,
    PRIMARY KEY (product_id)
)
DISTSTYLE ALL
SORTKEY (category, subcategory);


-- ============================================================================
-- FACT: Orders
-- ============================================================================
CREATE TABLE IF NOT EXISTS fact_orders (
    order_id        VARCHAR(20)     NOT NULL    ENCODE zstd,
    customer_id     VARCHAR(20)     NOT NULL    ENCODE zstd,
    order_date      DATE            NOT NULL    ENCODE az64,
    order_time      VARCHAR(8)      NOT NULL    ENCODE zstd,
    status          VARCHAR(20)     NOT NULL    ENCODE zstd,
    total_amount    DECIMAL(12,2)   NOT NULL    ENCODE az64,
    discount_amount DECIMAL(12,2)   NOT NULL    DEFAULT 0   ENCODE az64,
    shipping_cost   DECIMAL(10,2)   NOT NULL    DEFAULT 0   ENCODE az64,
    PRIMARY KEY (order_id)
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (order_date);


-- ============================================================================
-- FACT: Order Items (line items)
-- ============================================================================
CREATE TABLE IF NOT EXISTS fact_order_items (
    order_item_id   VARCHAR(20)     NOT NULL    ENCODE zstd,
    order_id        VARCHAR(20)     NOT NULL    ENCODE zstd,
    product_id      VARCHAR(20)     NOT NULL    ENCODE zstd,
    quantity        INTEGER         NOT NULL    ENCODE az64,
    unit_price      DECIMAL(10,2)   NOT NULL    ENCODE az64,
    discount_pct    INTEGER         NOT NULL    DEFAULT 0   ENCODE az64,
    line_total      DECIMAL(12,2)   NOT NULL    ENCODE az64,
    PRIMARY KEY (order_item_id)
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (order_id);
