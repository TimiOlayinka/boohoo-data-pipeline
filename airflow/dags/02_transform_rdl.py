"""
DAG 2: RDL (Raw Data Layer)
Runs dbt models tagged with 'rdl' to load and deduplicate raw source data.
Source systems: Boohoo Commerce, Salesforce, Shopify, Magento, Oracle Commerce
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
    dag_id="02_transform_rdl",
    default_args=default_args,
    description="Raw Data Layer: Deduplicate and normalise source data from 5 platforms",
    schedule_interval="30 1 * * *",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["transform", "dbt", "rdl"],
) as dag:

    dbt_run_rdl = BashOperator(
        task_id="dbt_run_rdl",
        bash_command=f"cd {DBT_DIR} && dbt run --select tag:rdl --profiles-dir .",
    )

    dbt_test_rdl = BashOperator(
        task_id="dbt_test_rdl",
        bash_command=f"cd {DBT_DIR} && dbt test --select tag:rdl --profiles-dir .",
    )

    dbt_run_rdl >> dbt_test_rdl
