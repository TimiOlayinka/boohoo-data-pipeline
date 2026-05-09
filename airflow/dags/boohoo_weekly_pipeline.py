"""
Boohoo Group Weekly Data Pipeline DAG

Orchestrates the end-to-end data flow:
  1. Generate synthetic data across 7 brands → S3
  2. COPY raw JSONL into Redshift raw schema
  3. Run dbt staging models (normalize 5 source schemas)
  4. Run dbt mart models (unified dimensions + facts)
  5. Run dbt tests (data quality)
  6. Notify on success/failure

Schedule: Weekly, Sundays 02:00 UTC
Note: This DAG is for portfolio showcase. Actual orchestration uses
      EventBridge + Step Functions ($0/month vs MWAA ~$350/month).
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup


default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=1),
}


with DAG(
    dag_id="boohoo_weekly_pipeline",
    default_args=default_args,
    description="Weekly E2E pipeline: S3 → Redshift → dbt → Marts",
    schedule_interval="0 2 * * SUN",  # Every Sunday at 2AM UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["boohoo", "production", "weekly"],
    doc_md=__doc__,
) as dag:

    # ── Step 1: Generate Data ──────────────────────────────────────
    generate_data = LambdaInvokeFunctionOperator(
        task_id="generate_boohoo_data",
        function_name="boohoo-data-generator",
        payload='{"n_customers": 5500, "n_products": 580, "n_orders": 55000}',
        aws_conn_id="aws_default",
    )

    # ── Step 2: Load to Redshift ───────────────────────────────────
    with TaskGroup("load_to_redshift", tooltip="COPY from S3 → Redshift raw") as load_group:
        BRANDS = {
            "boohoo": "boohoo_commerce",
            "boohoo_man": "boohoo_commerce",
            "prettylittlething": "salesforce_commerce",
            "nastygal": "shopify",
            "karen_millen": "magento",
            "coast": "magento",
            "debenhams": "oracle_commerce",
        }
        DATASETS = ["customers", "products", "orders", "order_items"]

        for brand, source in BRANDS.items():
            for dataset in DATASETS:
                RedshiftDataOperator(
                    task_id=f"copy_{brand}_{dataset}",
                    cluster_identifier="boohoo-workgroup",
                    database="boohoo_dwh",
                    sql=f"""
                        COPY raw.{brand}_{dataset}
                        FROM 's3://boohoo-dns-rdl-staging/{brand}/{source}/{dataset}/history/ingest_date={{{{ ds }}}}/'
                        IAM_ROLE 'arn:aws:iam::332779204498:role/RedshiftS3ReadRole'
                        FORMAT AS JSON 'auto'
                        GZIP
                        TIMEFORMAT 'auto';
                    """,
                    aws_conn_id="aws_default",
                )

    # ── Step 3: dbt Staging ────────────────────────────────────────
    with TaskGroup("dbt_staging", tooltip="Normalize source schemas") as dbt_staging:
        dbt_staging_run = BashOperator(
            task_id="dbt_run_staging",
            bash_command="cd /opt/dbt && dbt run --select staging",
        )

    # ── Step 4: dbt Marts ──────────────────────────────────────────
    with TaskGroup("dbt_marts", tooltip="Build unified dimensions + facts") as dbt_marts:
        dbt_marts_run = BashOperator(
            task_id="dbt_run_marts",
            bash_command="cd /opt/dbt && dbt run --select intermediate marts",
        )

    # ── Step 5: dbt Tests ──────────────────────────────────────────
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/dbt && dbt test",
    )

    # ── Step 6: Generate Docs ──────────────────────────────────────
    dbt_docs = BashOperator(
        task_id="dbt_docs_generate",
        bash_command="cd /opt/dbt && dbt docs generate",
    )

    # ── DAG Dependencies ──────────────────────────────────────────
    generate_data >> load_group >> dbt_staging >> dbt_marts >> dbt_test >> dbt_docs
