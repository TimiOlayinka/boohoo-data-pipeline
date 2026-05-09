# 🏗️ Boohoo Group — Enterprise Data Pipeline

**Multi-brand, multi-source serverless data warehouse on AWS**

![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900?logo=amazon-aws&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-Data_Transform-FF694B?logo=dbt&logoColor=white)
![Redshift](https://img.shields.io/badge/Redshift-Serverless-8C4FFF?logo=amazon-redshift&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)

*A production-grade data engineering pipeline that ingests data from 7 fashion brands — each running a different e-commerce platform — normalises heterogeneous schemas through a 3-layer DWH architecture, and delivers unified analytics.*

---

## 📐 Architecture

```mermaid
flowchart LR
    subgraph Sources["Source Systems"]
        BC[Boohoo Commerce]
        SF[Salesforce SFCC]
        SH[Shopify]
        MG[Magento]
        OC[Oracle Commerce]
    end

    subgraph Ingest["Ingestion"]
        EB[EventBridge Weekly]
        LG[Lambda Generator]
    end

    subgraph Lake["S3 Data Lake"]
        S3[boohoo-dns-rdl-staging]
    end

    subgraph DWH["Redshift Serverless"]
        RDL[RDL Layer]
        ODL[ODL Star Schema]
        ADL[ADL BI Layer]
    end

    subgraph BI["Dashboards"]
        LS[Looker Studio]
    end

    EB --> LG
    BC --> LG
    SF --> LG
    SH --> LG
    MG --> LG
    OC --> LG
    LG --> S3
    S3 --> RDL
    RDL --> ODL
    ODL --> ADL
    ADL --> LS
```

### Orchestration Flow

```mermaid
sequenceDiagram
    participant EB as EventBridge
    participant SF as Step Functions
    participant L1 as Data Generator
    participant S3 as S3 Data Lake
    participant L2 as Redshift Loader
    participant RS as Redshift
    participant L3 as dbt Runner

    EB->>SF: Weekly trigger
    SF->>L1: Generate data
    L1->>S3: 28 JSONL.GZ files
    L1-->>SF: Done
    SF->>L2: Load raw data
    L2->>RS: COPY from S3
    L2-->>SF: Done
    SF->>L3: Run dbt
    L3->>RS: 30 model transforms
    L3-->>SF: Done
```

---

## 📊 Data Model

### Multi-Brand Portfolio

This pipeline simulates a real-world enterprise challenge: **7 acquired brands** running on **5 different e-commerce platforms**, each with its own schema conventions.

| Brand | Source System | ID Field | Price Field | Orders |
|-------|-------------|----------|------------|--------|
| **Boohoo** | Boohoo Commerce | `sku` | `selling_price` | 15,000 |
| **BoohooMAN** | Boohoo Commerce | `sku` | `selling_price` | 8,000 |
| **PrettyLittleThing** | Salesforce Commerce | `product_id` | `price_book_price` | 12,000 |
| **NastyGal** | Shopify | `variant_id` | `price` | 6,000 |
| **Karen Millen** | Magento | `entity_id` | `price` | 4,000 |
| **Coast** | Magento | `entity_id` | `price` | 3,000 |
| **Debenhams** | Oracle Commerce | `item_id` | `list_price` | 7,000 |

> **The DWH challenge:** Each platform uses completely different field names for the same concept. The RDL layer normalises these into a single unified schema.

### Star Schema (ODL)

```mermaid
erDiagram
    dim_customers ||--o{ fact_orders : customer_sk
    dim_products ||--o{ fact_orders : product_sk
    dim_time ||--o{ fact_orders : order_date
    map_brand ||--o{ fact_orders : brand

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
    }

    dim_products {
        varchar product_sk PK
        varchar product_nk
        varchar product_name
        varchar category
        numeric current_price
        numeric cost_price
        numeric margin_pct
        varchar brand
    }

    fact_orders {
        varchar order_sk PK
        varchar customer_sk FK
        timestamp order_timestamp
        numeric total_amount
        numeric net_revenue
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
    }
```

---

## 🏛️ DWH Layers (RDL → ODL → ADL)

```mermaid
flowchart TB
    subgraph RDL["RDL - Raw Data Layer"]
        R1[rdl_boohoo_commerce]
        R2[rdl_salesforce_commerce]
        R3[rdl_shopify]
        R4[rdl_magento]
        R5[rdl_oracle_commerce]
    end

    subgraph ODL["ODL - Operational Data Layer"]
        D1[dim_customers]
        D2[dim_products]
        D3[dim_time]
        F1[fact_orders]
        M1[map_brand]
    end

    subgraph ADL["ADL - Analytics / BI Layer"]
        B1[fact_revenue_by_brand]
        B2[fact_daily_sales]
        B3[fact_customer_segments]
        B4[fact_product_performance]
    end

    RDL --> ODL
    ODL --> ADL
```

| Layer | Schema | Purpose | Models |
|-------|--------|---------|--------|
| **RDL** | `rdl_{source}` | Raw data dedup from `_history` tables. Source field names aliased to unified names. | 21 |
| **ODL** | `odl` | Star schema with surrogate keys (`_sk`), natural keys (`_nk`), conformed dimensions, calculated metrics. | 5 |
| **ADL** | `bi` | Pre-aggregated materialised tables optimised for BI tool queries. | 4 |

### Schema Normalisation Example

The same "product ID" concept across 5 platforms:

```
Boohoo Commerce:   sku           → product_id
Salesforce SFCC:   product_id    → product_id  
Shopify:           variant_id    → product_id
Magento:           entity_id     → product_id
Oracle Commerce:   item_id       → product_id
```

---

## 🗂️ S3 Data Lake Structure

```
s3://boohoo-dns-rdl-staging/
├── boohoo/boohoo_commerce/
│   ├── customers/history/ingest_date=2026-05-09/customers.jsonl.gz
│   ├── products/history/ingest_date=2026-05-09/products.jsonl.gz
│   ├── orders/history/ingest_date=2026-05-09/orders.jsonl.gz
│   └── order_items/history/ingest_date=2026-05-09/order_items.jsonl.gz
├── prettylittlething/salesforce_commerce/...
├── nastygal/shopify/...
├── karen_millen/magento/...
├── coast/magento/...
└── debenhams/oracle_commerce/...
```

**Path pattern:** `{brand}/{source}/{dataset}/history/ingest_date={yyyy-mm-dd}/{dataset}.jsonl.gz`

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Orchestration** | EventBridge + Step Functions | Weekly scheduling + state management |
| **Compute** | AWS Lambda (Python 3.12) | Data generation, loading, dbt execution |
| **Storage** | Amazon S3 (JSONL.GZ) | Partitioned data lake with Hive-style paths |
| **Warehouse** | Redshift Serverless | Auto-scaling columnar analytics engine |
| **Transformation** | dbt Core | 30 SQL models across 3 layers |
| **Infrastructure** | AWS CDK (Python) | Infrastructure as Code |
| **BI** | Google Looker Studio | Interactive dashboards from ADL |
| **Showcase** | Apache Airflow DAG | Portfolio orchestration demo |

---

## 📁 Project Structure

```
boohoo-data-pipeline/
│
├── lambda/
│   ├── data_generator/         # 7 brands × 4 datasets (config.py + handler.py)
│   └── redshift_loader/        # COPY from S3 with manifest files
│
├── dbt/
│   ├── dbt_project.yml         # Layer → schema mapping
│   └── models/
│       ├── rdl/                # Raw Data Layer (21 models)
│       │   ├── boohoo_commerce/     → sku → product_id
│       │   ├── salesforce_commerce/ → product_id → product_id
│       │   ├── shopify/             → variant_id → product_id
│       │   ├── magento/             → entity_id → product_id
│       │   └── oracle_commerce/     → item_id → product_id
│       ├── odl/                # Operational Data Layer (5 models)
│       │   ├── dim/            #   dim_customers, dim_products, dim_time
│       │   ├── fact/           #   fact_orders
│       │   └── map/            #   map_brand
│       └── adl/bi/             # Analytics Data Layer (4 models)
│
├── airflow/dags/               # Showcase Airflow DAG
├── cdk/stacks/                 # CDK infrastructure
├── sql/                        # DDL + views
└── scripts/                    # Deploy / teardown helpers
```

---

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/TimiOlayinka/boohoo-data-pipeline.git
cd boohoo-data-pipeline

# Install
pip install -r requirements.txt

# Deploy
cdk bootstrap && cdk deploy

# Generate data
python lambda/data_generator/handler.py

# Run dbt
cd dbt && dbt deps && dbt run && dbt test
```

---

## 💰 Cost Estimate

| Service | Monthly | Notes |
|---------|---------|-------|
| S3 | ~$0.01 | < 50MB JSONL.GZ |
| Lambda | ~$0.00 | Free tier |
| Redshift Serverless | ~$0.50–2.00 | Auto-pauses when idle |
| Step Functions | ~$0.00 | 4 transitions/week |
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

---

**Built by [Timi Olayinka](https://github.com/TimiOlayinka)** — Data Engineering & AI Automation
