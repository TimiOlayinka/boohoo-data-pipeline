"""
DAG 1.5: S3 → Redshift Loader
Copies freshly generated JSONL.GZ files from S3 into Redshift _history tables.
Runs after ingestion, before RDL transformation.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.sensors.external_task import ExternalTaskSensor
import boto3

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

REGION = "eu-west-2"
BUCKET = "boohoo-dns-rdl-staging"
IAM_ROLE = "arn:aws:iam::332779204498:role/BoohooDataGeneratorRole"
REDSHIFT_WORKGROUP = "bellosdata"
REDSHIFT_DB = "boohoo_dwh"

# Mapping: (brand, source, dataset) → (schema, table)
COPY_JOBS = [
    # ── Boohoo Commerce ──
    ("boohoo", "boohoo_commerce", "customers", "rdl_boohoo_commerce", "boohoo_customers_history"),
    ("boohoo", "boohoo_commerce", "products", "rdl_boohoo_commerce", "boohoo_products_history"),
    ("boohoo", "boohoo_commerce", "orders", "rdl_boohoo_commerce", "boohoo_orders_history"),
    ("boohoo", "boohoo_commerce", "order_items", "rdl_boohoo_commerce", "boohoo_order_items_history"),
    ("boohoo_man", "boohoo_commerce", "customers", "rdl_boohoo_commerce", "boohoo_man_customers_history"),
    ("boohoo_man", "boohoo_commerce", "products", "rdl_boohoo_commerce", "boohoo_man_products_history"),
    ("boohoo_man", "boohoo_commerce", "orders", "rdl_boohoo_commerce", "boohoo_man_orders_history"),
    ("boohoo_man", "boohoo_commerce", "order_items", "rdl_boohoo_commerce", "boohoo_man_order_items_history"),
    # ── Salesforce Commerce (PLT) ──
    ("prettylittlething", "salesforce_commerce", "customers", "rdl_salesforce_commerce", "plt_customers_history"),
    ("prettylittlething", "salesforce_commerce", "products", "rdl_salesforce_commerce", "plt_products_history"),
    ("prettylittlething", "salesforce_commerce", "orders", "rdl_salesforce_commerce", "plt_orders_history"),
    ("prettylittlething", "salesforce_commerce", "order_items", "rdl_salesforce_commerce", "plt_order_items_history"),
    # ── Shopify (NastyGal) ──
    ("nastygal", "shopify", "customers", "rdl_shopify", "nastygal_customers_history"),
    ("nastygal", "shopify", "products", "rdl_shopify", "nastygal_products_history"),
    ("nastygal", "shopify", "orders", "rdl_shopify", "nastygal_orders_history"),
    ("nastygal", "shopify", "order_items", "rdl_shopify", "nastygal_order_items_history"),
    # ── Magento (Karen Millen & Coast) ──
    ("karen_millen", "magento", "customers", "rdl_magento", "karen_millen_customers_history"),
    ("karen_millen", "magento", "products", "rdl_magento", "karen_millen_products_history"),
    ("karen_millen", "magento", "orders", "rdl_magento", "karen_millen_orders_history"),
    ("karen_millen", "magento", "order_items", "rdl_magento", "karen_millen_order_items_history"),
    ("coast", "magento", "customers", "rdl_magento", "coast_customers_history"),
    ("coast", "magento", "products", "rdl_magento", "coast_products_history"),
    ("coast", "magento", "orders", "rdl_magento", "coast_orders_history"),
    ("coast", "magento", "order_items", "rdl_magento", "coast_order_items_history"),
    # ── Oracle Commerce (Debenhams) ──
    ("debenhams", "oracle_commerce", "customers", "rdl_oracle_commerce", "debenhams_customers_history"),
    ("debenhams", "oracle_commerce", "products", "rdl_oracle_commerce", "debenhams_products_history"),
    ("debenhams", "oracle_commerce", "orders", "rdl_oracle_commerce", "debenhams_orders_history"),
    ("debenhams", "oracle_commerce", "order_items", "rdl_oracle_commerce", "debenhams_order_items_history"),
]


def copy_s3_to_redshift(brand, source, dataset, schema, table, **kwargs):
    """Execute Redshift COPY command to load JSONL.GZ from S3."""
    execution_date = kwargs["ds"]
    s3_path = f"s3://{BUCKET}/{brand}/{source}/{dataset}/history/ingest_date={execution_date}/"

    sql = f"""
        COPY "{schema}"."{table}"
        FROM '{s3_path}'
        IAM_ROLE '{IAM_ROLE}'
        FORMAT AS JSON 'auto'
        GZIP
        TIMEFORMAT 'auto'
        DATEFORMAT 'auto'
        TRUNCATECOLUMNS
        ACCEPTINVCHARS
        REGION '{REGION}';
    """

    client = boto3.client("redshift-data", region_name=REGION)
    response = client.execute_statement(
        WorkgroupName=REDSHIFT_WORKGROUP,
        Database=REDSHIFT_DB,
        Sql=sql,
    )
    statement_id = response["Id"]
    print(f"✅ COPY {schema}.{table} ← {s3_path}")
    print(f"   Statement ID: {statement_id}")


with DAG(
    dag_id="01b_s3_to_redshift",
    default_args=default_args,
    description="Load JSONL.GZ files from S3 into Redshift history tables",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["ingestion", "redshift", "copy"],
) as dag:

    wait_for_ingestion = ExternalTaskSensor(
        task_id="wait_for_ingestion",
        external_dag_id="01_ingestion",
        external_task_id=None,
        timeout=600,
        poke_interval=30,
    )

    copy_tasks = []
    for brand, source, dataset, schema, table in COPY_JOBS:
        task = PythonOperator(
            task_id=f"copy_{brand}_{dataset}",
            python_callable=copy_s3_to_redshift,
            op_kwargs={
                "brand": brand,
                "source": source,
                "dataset": dataset,
                "schema": schema,
                "table": table,
            },
        )
        copy_tasks.append(task)

    wait_for_ingestion >> copy_tasks
