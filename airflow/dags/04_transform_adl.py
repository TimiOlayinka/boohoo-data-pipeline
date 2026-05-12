"""
DAG 4: ADL (Analytics Data Layer)
Runs dbt models tagged with 'adl' to build pre-aggregated BI tables.
Models: fact_revenue_by_brand, fact_daily_sales, fact_customer_segments, fact_product_performance
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.sensors.external_task import ExternalTaskSensor

default_args = {
    "owner": "timi.olayinka",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=3),
}

DBT_DIR = "/opt/airflow/dbt"

with DAG(
    dag_id="04_transform_adl",
    default_args=default_args,
    description="Analytics Data Layer: Pre-aggregated tables for Looker Studio dashboards",
    schedule_interval="50 1 * * 1,3,5",  # Mon/Wed/Fri,
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["transform", "dbt", "adl", "bi"],
) as dag:

    dbt_run_adl = BashOperator(
        task_id="dbt_run_adl",
        bash_command=f"cd {DBT_DIR} && dbt run --select tag:adl --profiles-dir .",
    )

    dbt_test_adl = BashOperator(
        task_id="dbt_test_adl",
        bash_command=f"cd {DBT_DIR} && dbt test --select tag:adl --profiles-dir .",
    )

    dbt_run_adl >> dbt_test_adl
