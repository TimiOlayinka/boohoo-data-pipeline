<![CDATA[<div align="center">

# 🏗️ Boohoo Group — Enterprise Data Pipeline

**Multi-brand, multi-source serverless data warehouse on AWS**

[![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![dbt](https://img.shields.io/badge/dbt-Data_Transform-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Redshift](https://img.shields.io/badge/Redshift-Serverless-8C4FFF?logo=amazon-redshift&logoColor=white)](https://aws.amazon.com/redshift/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)

*A production-grade data engineering pipeline that ingests data from 7 fashion brands — each running a different e-commerce platform — normalises heterogeneous schemas through a 3-layer DWH architecture, and delivers unified analytics.*

---

[Architecture](#-architecture) · [Data Model](#-data-model) · [DWH Layers](#-dwh-layers-rdl--odl--adl) · [Tech Stack](#%EF%B8%8F-tech-stack) · [Quick Start](#-quick-start)

</div>

---

## 📐 Architecture

```mermaid
flowchart LR
    subgraph Sources["Source Systems (5 Platforms)"]
        BC["Boohoo Commerce\n(Boohoo, BoohooMAN)"]
        SF["Salesforce Commerce\n(PLT)"]
        SH["Shopify\n(NastyGal)"]
        MG["Magento\n(Karen Millen, Coast)"]
        OC["Oracle Commerce\n(Debenhams)"]
    end

    subgraph Ingest["Ingestion Layer"]
        EB["⏱️ EventBridge\nWeekly Schedule"]
        LG["λ Lambda\nData Generator"]
    end

    subgraph Storage["S3 Data Lake"]
        S3["📦 s3://boohoo-dns-rdl-staging\n{brand}/{source}/{dataset}/\nhistory/ingest_date={date}/\n{dataset}.jsonl.gz"]
    end

    subgraph DWH["Redshift Serverless"]
        RDL["RDL Layer\n(Raw Data Layer)\nDedup from _history"]
        ODL["ODL Layer\n(Operational Data Layer)\n⭐ Star Schema"]
        ADL["ADL / BI Layer\n(Analytics Data Layer)\nMaterialised Tables"]
    end

    subgraph Transform["Transformation"]
        DBT["🔄 dbt Core\n30 Models"]
    end

    subgraph BI["Business Intelligence"]
        LS["📊 Looker Studio\nDashboards"]
    end

    EB --> LG
    BC --> LG
    SF --> LG
    SH --> LG
    MG --> LG
    OC --> LG
    LG --> S3
    S3 -->|"COPY + Manifest"| RDL
    RDL -->|dbt| ODL
    ODL -->|dbt| ADL
    DBT -.->|"Orchestrates"| RDL
    DBT -.->|"Orchestrates"| ODL
    DBT -.->|"Orchestrates"| ADL
    ADL --> LS
```

### Orchestration Flow

```mermaid
sequenceDiagram
    participant EB as EventBridge<br/>(Sunday 2AM)
    participant SF as Step Functions
    participant L1 as Lambda<br/>Data Generator
    participant S3 as S3 Data Lake
    participant L2 as Lambda<br/>Redshift Loader
    participant RS as Redshift<br/>Serverless
    participant L3 as Lambda<br/>dbt Runner

    EB->>SF: Trigger weekly pipeline
    SF->>L1: Step 1: Generate data
    L1->>S3: 28 JSONL.GZ files<br/>(7 brands × 4 datasets)
    L1-->>SF: ✅ Complete
    SF->>L2: Step 2: Load raw data
    L2->>RS: COPY from S3<br/>(manifest + GZIP)
    L2-->>SF: ✅ Complete
    SF->>L3: Step 3: Run dbt
    L3->>RS: RDL → ODL → ADL<br/>(30 models)
    L3-->>SF: ✅ Complete
    SF-->>EB: Pipeline success ✅
```

---

## 📊 Data Model

### Multi-Brand Portfolio

This pipeline simulates a real-world enterprise challenge: **7 acquired brands** running on **5 different e-commerce platforms**, each with its own schema conventions.

| Brand | Source System | Schema Style | Volume |
|-------|-------------|-------------|--------|
| **Boohoo** | Boohoo Commerce (Custom) | `sku`, `selling_price`, `order_id` | 1,500 customers · 150 SKUs · 15K orders |
| **BoohooMAN** | Boohoo Commerce (Custom) | `sku`, `selling_price`, `order_id` | 800 · 80 · 8K |
| **PrettyLittleThing** | Salesforce Commerce Cloud | `product_id`, `price_book_price`, `order_no` | 1,200 · 120 · 12K |
| **NastyGal** | Shopify | `variant_id`, `price`, `id` | 600 · 60 · 6K |
| **Karen Millen** | Magento | `entity_id`, `price`, `increment_id` | 400 · 50 · 4K |
| **Coast** | Magento | `entity_id`, `price`, `increment_id` | 300 · 40 · 3K |
| **Debenhams** | Oracle Commerce | `item_id`, `list_price`, `order_number` | 700 · 80 · 7K |

> **The DWH challenge:** Each platform uses completely different field names for the same concept. The RDL layer normalises these into a single unified schema.

### Star Schema (ODL)

```mermaid
erDiagram
    dim_customers ||--o{ fact_orders : "customer_sk"
    dim_products ||--o{ fact_orders : "product_sk"
    dim_time ||--o{ fact_orders : "order_date"
    map_brand ||--o{ fact_orders : "brand"

    dim_customers {
        varchar customer_sk PK
        varchar customer_nk
        varchar email
        varchar first_name
        varchar last_name
        varchar city
        varchar country
        varchar customer_segment
        date registration_date
        varchar brand
        varchar source_system
    }

    dim_products {
        varchar product_sk PK
        varchar product_nk
        varchar product_name
        varchar colour
        varchar category
        numeric current_price
        numeric cost_price
        numeric margin_pct
        numeric discount_pct
        varchar brand
    }

    fact_orders {
        varchar order_sk PK
        varchar customer_sk FK
        timestamp order_timestamp
        numeric total_amount
        numeric net_revenue
        numeric discount_amount
        varchar status
        varchar payment_method
        varchar brand
    }

    dim_time {
        date date_day PK
        int day_of_week
        varchar month_name
        int quarter
        int year
        boolean is_peak_season
    }

    map_brand {
        varchar brand PK
        varchar source_system
        varchar brand_tier
        varchar website
    }
```

---

## 🏛️ DWH Layers (RDL → ODL → ADL)

Following enterprise data warehouse conventions:

```mermaid
flowchart TB
    subgraph RDL["RDL — Raw Data Layer"]
        direction TB
        R1["rdl_boohoo_commerce\n├── boohoo_customers\n├── boohoo_products\n└── boohoo_orders"]
        R2["rdl_salesforce_commerce\n├── plt_customers\n├── plt_products\n└── plt_orders"]
        R3["rdl_shopify\n├── nastygal_customers\n├── nastygal_products\n└── nastygal_orders"]
        R4["rdl_magento\n├── karen_millen_*\n└── coast_*"]
        R5["rdl_oracle_commerce\n├── debenhams_customers\n├── debenhams_products\n└── debenhams_orders"]
    end

    subgraph ODL["ODL — Operational Data Layer"]
        direction TB
        D1["dim_customers\n(unified, deduped)"]
        D2["dim_products\n(with margin calc)"]
        D3["dim_time\n(conformed)"]
        F1["fact_orders\n(with surrogate keys)"]
        M1["map_brand\n(reference mapping)"]
    end

    subgraph ADL["ADL — Analytics Data Layer (BI)"]
        direction TB
        B1["fact_revenue_by_brand"]
        B2["fact_daily_sales"]
        B3["fact_customer_segments"]
        B4["fact_product_performance"]
    end

    RDL -->|"dbt: normalize\n+ deduplicate"| ODL
    ODL -->|"dbt: aggregate\n+ enrich"| ADL

    style RDL fill:#1a1a2e,stroke:#e94560,color:#fff
    style ODL fill:#1a1a2e,stroke:#0f3460,color:#fff
    style ADL fill:#1a1a2e,stroke:#16213e,color:#fff
```

| Layer | Schema | Purpose | Models |
|-------|--------|---------|--------|
| **RDL** | `rdl_{source_name}` | Raw data deduplication from `_history` tables. Source-specific field names preserved, then aliased to unified names. | 21 |
| **ODL** | `odl` | Star schema with surrogate keys (`_sk`), natural keys (`_nk`), conformed dimensions, and calculated metrics. | 5 |
| **ADL** | `bi` | Pre-aggregated materialized tables optimised for BI tool queries. Joins facts with dimensions. | 4 |

### Schema Normalization Example

The same "product ID" concept has 5 different field names across source systems:

```sql
-- Boohoo Commerce:   sku           → product_id
-- Salesforce (SFCC):  product_id    → product_id  
-- Shopify:            variant_id    → product_id
-- Magento:            entity_id     → product_id
-- Oracle Commerce:    item_id       → product_id
```

---

## 🗂️ S3 Data Lake Structure

Following enterprise naming conventions:

```
s3://boohoo-dns-rdl-staging/
├── boohoo/
│   └── boohoo_commerce/
│       ├── customers/history/ingest_date=2026-05-09/customers.jsonl.gz
│       ├── products/history/ingest_date=2026-05-09/products.jsonl.gz
│       ├── orders/history/ingest_date=2026-05-09/orders.jsonl.gz
│       └── order_items/history/ingest_date=2026-05-09/order_items.jsonl.gz
├── prettylittlething/
│   └── salesforce_commerce/
│       └── ...
├── nastygal/
│   └── shopify/
│       └── ...
├── karen_millen/
│   └── magento/
│       └── ...
├── coast/
│   └── magento/
│       └── ...
└── debenhams/
    └── oracle_commerce/
        └── ...
```

**Path pattern:** `{brand}/{source}/{dataset}/history/ingest_date={yyyy-mm-dd}/{dataset}.jsonl.gz`

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Orchestration** | EventBridge + Step Functions | Weekly scheduling + pipeline state management |
| **Compute** | AWS Lambda (Python 3.12) | Data generation, loading, dbt execution |
| **Storage** | Amazon S3 (JSONL.GZ) | Partitioned data lake with Hive-style paths |
| **Warehouse** | Redshift Serverless | Auto-scaling columnar analytics engine |
| **Transformation** | dbt Core | 30 SQL models across 3 layers (RDL/ODL/ADL) |
| **Infrastructure** | AWS CDK (Python) | Infrastructure as Code |
| **CI/CD** | GitHub Actions | Automated deployment on merge |
| **BI** | Google Looker Studio | Interactive dashboards connected to ADL |
| **Showcase** | Apache Airflow DAG | Portfolio demonstration of orchestration skills |

---

## 📁 Project Structure

```
boohoo-data-pipeline/
│
├── 📂 lambda/
│   ├── data_generator/              # Synthetic data for 7 brands × 4 datasets
│   │   ├── config.py                # Brand-source mapping + schema definitions
│   │   └── handler.py               # Generator with realistic distributions
│   └── redshift_loader/
│       └── handler.py               # COPY from S3 with manifest files
│
├── 📂 dbt/
│   ├── dbt_project.yml              # Layer → schema mapping
│   ├── profiles.yml                 # Redshift connection
│   ├── packages.yml                 # dbt_utils dependency
│   └── models/
│       ├── rdl/                     # 🔴 Raw Data Layer (21 models)
│       │   ├── boohoo_commerce/     #    sku → product_id
│       │   ├── salesforce_commerce/ #    product_id → product_id
│       │   ├── shopify/             #    variant_id → product_id
│       │   ├── magento/             #    entity_id → product_id
│       │   └── oracle_commerce/     #    item_id → product_id
│       ├── odl/                     # 🔵 Operational Data Layer (5 models)
│       │   ├── dim/                 #    dim_customers, dim_products, dim_time
│       │   ├── fact/                #    fact_orders
│       │   └── map/                 #    map_brand
│       └── adl/bi/                  # 🟢 Analytics Data Layer (4 models)
│                                    #    fact_revenue_by_brand, fact_daily_sales
│                                    #    fact_customer_segments, fact_product_performance
│
├── 📂 airflow/
│   └── dags/
│       └── boohoo_weekly_pipeline.py # Showcase DAG with TaskGroups
│
├── 📂 cdk/
│   ├── app.py                       # CDK entry point
│   └── stacks/
│       └── data_pipeline_stack.py   # Lambda, S3, Redshift, EventBridge
│
├── 📂 sql/
│   ├── create_tables.sql            # Redshift DDL
│   └── create_views.sql             # Analytical views
│
├── 📂 scripts/
│   ├── deploy.sh                    # One-command deployment
│   ├── teardown.sh                  # Clean resource removal
│   └── generate_dbt_models.py       # Model generator utility
│
└── 📂 docs/
    └── looker_studio_setup.md       # BI connection guide
```

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/TimiOlayinka/boohoo-data-pipeline.git
cd boohoo-data-pipeline

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure AWS credentials
aws configure sso  # or set AWS_PROFILE

# 4. Deploy infrastructure
cdk bootstrap && cdk deploy

# 5. Generate initial data load
python lambda/data_generator/handler.py

# 6. Run dbt models
cd dbt && dbt deps && dbt run && dbt test
```

---

## 💰 Cost Estimate

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| S3 (< 50MB) | ~$0.01 | JSONL.GZ compressed |
| Lambda (4 functions, weekly) | ~$0.00 | Free tier |
| Redshift Serverless (8 RPU) | ~$0.50–2.00 | Auto-pauses after 5 min idle |
| Step Functions | ~$0.00 | 4 transitions/week |
| EventBridge | $0.00 | 1 scheduled rule |
| Secrets Manager | $0.40 | 1 secret |
| **Total** | **~$1–3/month** | |

---

## 🗺️ Roadmap

- [x] Multi-brand data generator (7 brands, 5 source systems)
- [x] S3 data lake with Hive-style partitioning
- [x] dbt project (30 models: RDL → ODL → ADL)
- [x] Airflow DAG (portfolio showcase)
- [ ] Redshift Serverless provisioning
- [ ] COPY + manifest ingestion pipeline
- [ ] Step Functions orchestrator
- [ ] EventBridge weekly schedule
- [ ] Looker Studio dashboards
- [ ] GitHub Actions CI/CD

---

<div align="center">

**Built by [Timi Olayinka](https://github.com/TimiOlayinka)** · Data Engineering & AI Automation

</div>
]]>
