# AWS Data Architecture Portfolio

A production-grade serverless data pipeline on AWS that demonstrates end-to-end data engineering skills — from data generation through to interactive BI dashboards.

## Architecture

```
EventBridge Scheduler → Lambda (Data Generator) → S3 → Redshift Serverless → Google Looker Studio
```

| Component | Service | Purpose |
|---|---|---|
| **Data Generation** | AWS Lambda (Python 3.12) | Generates realistic e-commerce data using Faker |
| **Storage** | Amazon S3 | Landing zone for CSV data files |
| **Data Warehouse** | Redshift Serverless | Columnar analytics engine with auto-scaling |
| **Orchestration** | EventBridge Scheduler | Triggers daily data generation |
| **Ingestion** | Lambda + Redshift Data API | Event-driven S3 → Redshift COPY |
| **Visualization** | Google Looker Studio | Free, shareable interactive dashboards |
| **Infrastructure** | AWS CDK (Python) | Infrastructure as Code |

## Data Model

### E-Commerce Analytics

- **dim_customers** — 5,000 customers with demographics, segments, signup dates
- **dim_products** — 500 products across categories with pricing
- **fact_orders** — 50,000 orders spanning 2 years with seasonal patterns
- **fact_order_items** — 150,000 line items with quantities, prices, discounts

## Prerequisites

- Python 3.12+
- AWS CLI configured with credentials
- AWS CDK v2 installed (`npm install -g aws-cdk`)
- An AWS account (new accounts get $300 Redshift Serverless free credit)

## Quick Start

```bash
# 1. Clone and install dependencies
cd aws-data-portfolio
pip install -r requirements.txt

# 2. Bootstrap CDK (first time only)
cdk bootstrap

# 3. Deploy all resources
cdk deploy --require-approval never

# 4. Generate initial data (triggers Lambda manually)
aws lambda invoke \
  --function-name portfolio-data-generator \
  --payload '{"initial_load": true}' \
  response.json

# 5. Verify data in Redshift (via Query Editor v2 in AWS Console)
# 6. Connect Google Looker Studio (see docs/looker_studio_setup.md)
```

## Teardown

```bash
# Remove all AWS resources to stop charges
cdk destroy
```

## Cost Estimate

| Service | Monthly | Notes |
|---|---|---|
| Lambda | ~$0.00 | Free tier |
| S3 | ~$0.01 | Small CSV files |
| Redshift Compute | $0–5 | Pay-per-query, auto-pauses |
| Redshift Storage | ~$0.50 | ~20GB compressed |
| Secrets Manager | ~$0.40 | 1 secret |
| Looker Studio | $0.00 | Free |
| **Total** | **~$1–6/mo** | After free trial |

## Project Structure

```
aws-data-portfolio/
├── cdk/
│   ├── app.py                          # CDK entry point
│   ├── cdk.json                        # CDK config
│   └── stacks/
│       └── data_pipeline_stack.py      # Main infrastructure stack
├── lambda/
│   ├── data_generator/
│   │   ├── handler.py                  # Dummy data generation
│   │   └── requirements.txt            # Faker, pandas
│   └── redshift_loader/
│       └── handler.py                  # S3 → Redshift COPY
├── sql/
│   ├── create_tables.sql               # Table DDL
│   └── create_views.sql                # Analytical views
├── scripts/
│   ├── deploy.sh                       # One-command deploy
│   └── teardown.sh                     # Clean teardown
├── docs/
│   └── looker_studio_setup.md          # Looker Studio guide
├── requirements.txt                    # CDK dependencies
└── README.md                           # This file
```
