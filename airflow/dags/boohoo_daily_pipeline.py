from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
import boto3
import time

# ─────────────────────────────────────────────
# DAG Configuration
# ─────────────────────────────────────────────

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

LAMBDA_FUNCTIONS = [
    "boohoo-ecommerce-customers",
    "boohoo-ecommerce-orders",
    "boohoo-ecommerce-products",
    "boohoo-marketing-meta-ads",
    "boohoo-marketing-google-ads",
    "boohoo-marketing-tiktok-ads",
    "boohoo-marketing-ga4-sessions",
    "boohoo-marketing-email-campaigns",
    "boohoo-marketing-influencers",
]

# ─────────────────────────────────────────────
# Task Functions
# ─────────────────────────────────────────────

def trigger_lambda(function_name, **kwargs):
    """Invoke a Lambda function and wait for completion."""
    client = boto3.client("lambda", region_name="eu-west-2")
    response = client.invoke(
        FunctionName=function_name,
        InvocationType="RequestResponse",
    )
    status = response["StatusCode"]
    print(f"{function_name} returned status: {status}")
    if status != 200:
        raise Exception(f"{function_name} failed with status {status}")


def wait_for_s3_landing(**kwargs):
    """Wait for data to settle in S3 before transformation."""
    print("Waiting 2 minutes for S3 data landing...")
    time.sleep(120)
    print("S3 data landing complete.")


# ─────────────────────────────────────────────
# DAG Definition
# ─────────────────────────────────────────────

with DAG(
    dag_id="boohoo_daily_pipeline",
    default_args=default_args,
    description="End-to-end Boohoo data pipeline: Generate → Transform → Test",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["boohoo", "production", "data-pipeline"],
) as dag:

    # ── Stage 1: Trigger all 9 data generators ──
    generate_tasks = []
    for fn_name in LAMBDA_FUNCTIONS:
        task = PythonOperator(
            task_id=f"generate_{fn_name.replace('boohoo-', '').replace('-', '_')}",
            python_callable=trigger_lambda,
            op_kwargs={"function_name": fn_name},
        )
        generate_tasks.append(task)

    # ── Stage 2: Wait for S3 data landing ──
    wait_task = PythonOperator(
        task_id="wait_for_s3_landing",
        python_callable=wait_for_s3_landing,
    )

    # ── Stage 3: dbt run (RDL → ODL → ADL) ──
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/airflow/dbt && dbt run --profiles-dir .",
    )

    # ── Stage 4: dbt test (Data Quality) ──
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/airflow/dbt && dbt test --profiles-dir .",
    )

    # ── Pipeline Flow ──
    generate_tasks >> wait_task >> dbt_run >> dbt_test
