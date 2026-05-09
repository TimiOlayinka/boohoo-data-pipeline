#!/usr/bin/env python3
"""
AWS CDK App — Data Architecture Portfolio

Deploys a complete serverless data pipeline:
  EventBridge → Lambda (data gen) → S3 → Lambda (loader) → Redshift Serverless
"""

import aws_cdk as cdk

from stacks.data_pipeline_stack import DataPipelineStack


app = cdk.App()

DataPipelineStack(
    app,
    "DataPortfolioStack",
    description="Portfolio data pipeline: Lambda → S3 → Redshift Serverless",
    env=cdk.Environment(
        # Default to London — change to your preferred region
        region=app.node.try_get_context("region") or "eu-west-2",
    ),
)

app.synth()
