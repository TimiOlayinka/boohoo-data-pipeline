# Connecting Google Looker Studio to Redshift Serverless

Step-by-step guide to connect your free Looker Studio dashboards to the Redshift Serverless data warehouse.

## Prerequisites

- Google account (free)
- Deployed AWS stack (run `scripts/deploy.sh` first)
- Redshift workgroup endpoint and credentials

## Step 1: Get Your Redshift Connection Details

From the AWS Console → Redshift → Serverless → Workgroups → `portfolio-wg`:

| Field | Where to Find |
|---|---|
| **Host** | Workgroup details → Endpoint (e.g., `portfolio-wg.123456789.eu-west-2.redshift-serverless.amazonaws.com`) |
| **Port** | `5439` |
| **Database** | `portfolio_db` |
| **Username** | `admin` |
| **Password** | AWS Console → Secrets Manager → `portfolio/redshift/admin` → Retrieve secret value |

## Step 2: Create a Looker Studio Data Source

1. Go to [lookerstudio.google.com](https://lookerstudio.google.com/)
2. Click **Create** → **Data source**
3. Search for **Amazon Redshift** connector
4. Select it and click **Authorize**
5. Enter your connection details:
   - **Host**: your workgroup endpoint
   - **Port**: `5439`
   - **Database**: `portfolio_db`
   - **Username**: `admin`
   - **Password**: from Secrets Manager
6. Click **Authenticate**

## Step 3: Select Data Tables/Views

Create one data source for each analytical view:

| Data Source Name | Table/View | Dashboard Page |
|---|---|---|
| Daily Revenue | `public.v_daily_revenue` | Executive Summary |
| Monthly Trends | `public.v_monthly_trends` | Executive Summary |
| Customer Segments | `public.v_customer_segments` | Customer Analytics |
| Top Customers | `public.v_top_customers` | Customer Analytics |
| Product Performance | `public.v_product_performance` | Product Performance |
| Category Performance | `public.v_category_performance` | Product Performance |
| Revenue by Geography | `public.v_revenue_by_geography` | Executive Summary |
| Order Status | `public.v_order_status` | Executive Summary |

## Step 4: Build the Dashboards

### Page 1: Executive Summary
- **Scorecards**: Total Revenue, Total Orders, Unique Customers, AOV
- **Line Chart**: Daily revenue trend (from `v_daily_revenue`)
- **Bar Chart**: Revenue by category (from `v_category_performance`)
- **Geo Map**: Revenue by country (from `v_revenue_by_geography`)
- **Donut Chart**: Order status distribution (from `v_order_status`)

### Page 2: Customer Analytics
- **Pie Chart**: Revenue by customer segment (from `v_customer_segments`)
- **Table**: Top 50 customers by lifetime value (from `v_top_customers`)
- **Bar Chart**: Customers by country (from `v_customer_segments`)
- **Scorecard**: New customers this month (from `v_monthly_trends`)

### Page 3: Product Performance
- **Bar Chart**: Top 10 products by revenue (from `v_product_performance`)
- **Heatmap/Table**: Category × month revenue (from `v_category_performance`)
- **Bar Chart**: Gross margin by category (from `v_product_performance`)
- **Table**: Full product list with KPIs (from `v_product_performance`)

## Step 5: Share the Dashboard

1. Click **Share** (top right)
2. Under **General access**, change to **Anyone with the link**
3. Set permission to **Viewer**
4. Copy the link
5. Send to clients — they can view and interact without a Google account

## Step 6: Optimize for Cost

Since Looker Studio queries Redshift live, each dashboard load costs RPU compute time.

**Tips to minimize cost:**
- Use **data extracts** in Looker Studio (caches data, reduces Redshift queries)
- Set **cache duration** to 12 hours in data source settings
- Pre-aggregate data in views (already done — our views handle this)
- Set Redshift **usage limits** in the console (e.g., max 10 RPU-hours/day)

## Troubleshooting

| Issue | Solution |
|---|---|
| Connection timeout | Check security group allows inbound 5439 from Looker Studio IPs |
| Authentication failed | Verify password in Secrets Manager matches |
| No tables visible | Ensure views are created (run `sql/create_views.sql`) |
| Slow dashboards | Enable data extracts and increase cache duration |
