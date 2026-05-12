"""
DAG 1: Ingestion Layer
Triggers all 9 Lambda micro-services to generate synthetic data into S3.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
import boto3

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

REGION = "eu-west-2"

ECOMMERCE_LAMBDAS = [
    "boohoo-ecommerce-customers",
    "boohoo-ecommerce-orders",
    "boohoo-ecommerce-products",
]

MARKETING_LAMBDAS = [
    "boohoo-marketing-meta-ads",
    "boohoo-marketing-google-ads",
    "boohoo-marketing-tiktok-ads",
    "boohoo-marketing-ga4-sessions",
    "boohoo-marketing-email-campaigns",
    "boohoo-marketing-influencers",
]


def invoke_lambda(function_name, **kwargs):
    """Invoke a Lambda function synchronously and validate response."""
    client = boto3.client("lambda", region_name=REGION)
    response = client.invoke(
        FunctionName=function_name,
        InvocationType="RequestResponse",
    )
    status = response["StatusCode"]
    print(f"✅ {function_name} → Status: {status}")
    if status != 200:
        raise Exception(f"❌ {function_name} failed with status {status}")


with DAG(
    dag_id="01_ingestion",
    default_args=default_args,
    description="Trigger AWS Lambda functions to generate and load data to S3",
    schedule_interval="10 1 * * 1,3,5",  # 01:10 UTC Mon/Wed/Fri
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["ingestion", "lambda", "s3"],
) as dag:

    with TaskGroup("ecommerce_data") as ecommerce_group:
        for fn in ECOMMERCE_LAMBDAS:
            PythonOperator(
                task_id=f"generate_{fn.replace('boohoo-', '').replace('-', '_')}",
                python_callable=invoke_lambda,
                op_kwargs={"function_name": fn},
            )

    with TaskGroup("marketing_data") as marketing_group:
        for fn in MARKETING_LAMBDAS:
            PythonOperator(
                task_id=f"generate_{fn.replace('boohoo-', '').replace('-', '_')}",
                python_callable=invoke_lambda,
                op_kwargs={"function_name": fn},
            )

    # Ecommerce and Marketing run in parallel
    [ecommerce_group, marketing_group]
