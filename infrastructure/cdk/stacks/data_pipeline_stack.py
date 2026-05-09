"""
DataPipelineStack — Core infrastructure for the data portfolio.

Resources created:
  • VPC with public subnets (for Redshift public access)
  • S3 bucket (data landing zone)
  • Lambda: data generator (triggered by EventBridge schedule)
  • Lambda: Redshift loader (triggered by S3 ObjectCreated)
  • Redshift Serverless namespace + workgroup
  • IAM roles with least-privilege policies
  • Secrets Manager for Redshift credentials
"""

from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    CfnOutput,
    SecretValue,
    aws_ec2 as ec2,
    aws_s3 as s3,
    aws_s3_notifications as s3n,
    aws_lambda as _lambda,
    aws_lambda_python_alpha as lambda_python,
    aws_iam as iam,
    aws_secretsmanager as secretsmanager,
    aws_redshiftserverless as redshift,
    aws_events as events,
    aws_events_targets as targets,
)
from constructs import Construct


class DataPipelineStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ------------------------------------------------------------------ #
        # Context values (overridable via cdk.json or --context)
        # ------------------------------------------------------------------ #
        namespace_name = self.node.try_get_context("namespace_name") or "portfolio-ns"
        workgroup_name = self.node.try_get_context("workgroup_name") or "portfolio-wg"
        database_name = self.node.try_get_context("database_name") or "portfolio_db"
        admin_username = self.node.try_get_context("admin_username") or "admin"

        # ------------------------------------------------------------------ #
        # VPC — public subnets for Redshift public accessibility
        # ------------------------------------------------------------------ #
        vpc = ec2.Vpc(
            self,
            "PortfolioVpc",
            vpc_name="portfolio-vpc",
            max_azs=2,
            nat_gateways=0,  # No NAT to save cost
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="Public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24,
                ),
            ],
        )

        # Security group for Redshift — allows inbound on port 5439
        redshift_sg = ec2.SecurityGroup(
            self,
            "RedshiftSG",
            vpc=vpc,
            description="Allow Looker Studio and admin access to Redshift",
            allow_all_outbound=True,
        )

        # Google Looker Studio IP ranges (us-based)
        # In production, add specific IPs. For portfolio demo, allow broader access.
        redshift_sg.add_ingress_rule(
            ec2.Peer.any_ipv4(),
            ec2.Port.tcp(5439),
            "Redshift access — restrict to your IP + Looker Studio in production",
        )

        # ------------------------------------------------------------------ #
        # S3 Bucket — data landing zone
        # ------------------------------------------------------------------ #
        data_bucket = s3.Bucket(
            self,
            "DataLakeBucket",
            bucket_name=None,  # Auto-generated unique name
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            versioned=False,
            lifecycle_rules=[
                s3.LifecycleRule(
                    id="CleanupOldData",
                    expiration=Duration.days(90),
                    enabled=True,
                ),
            ],
        )

        # ------------------------------------------------------------------ #
        # Secrets Manager — Redshift admin password
        # ------------------------------------------------------------------ #
        redshift_secret = secretsmanager.Secret(
            self,
            "RedshiftAdminSecret",
            secret_name="portfolio/redshift/admin",
            description="Redshift Serverless admin credentials",
            generate_secret_string=secretsmanager.SecretStringGenerator(
                secret_string_template=f'{{"username": "{admin_username}"}}',
                generate_string_key="password",
                exclude_characters="\"@/\\",
                password_length=32,
            ),
        )

        # ------------------------------------------------------------------ #
        # IAM Role — Redshift access to S3
        # ------------------------------------------------------------------ #
        redshift_s3_role = iam.Role(
            self,
            "RedshiftS3AccessRole",
            assumed_by=iam.ServicePrincipal("redshift.amazonaws.com"),
            description="Allows Redshift to read from the data lake S3 bucket",
        )
        data_bucket.grant_read(redshift_s3_role)

        # ------------------------------------------------------------------ #
        # Redshift Serverless — Namespace
        # ------------------------------------------------------------------ #
        rs_namespace = redshift.CfnNamespace(
            self,
            "PortfolioNamespace",
            namespace_name=namespace_name,
            db_name=database_name,
            admin_username=admin_username,
            admin_user_password=redshift_secret.secret_value_from_json("password").unsafe_unwrap(),
            iam_roles=[redshift_s3_role.role_arn],
            default_iam_role_arn=redshift_s3_role.role_arn,
        )

        # ------------------------------------------------------------------ #
        # Redshift Serverless — Workgroup
        # ------------------------------------------------------------------ #
        rs_workgroup = redshift.CfnWorkgroup(
            self,
            "PortfolioWorkgroup",
            workgroup_name=workgroup_name,
            namespace_name=namespace_name,
            base_capacity=8,  # Minimum RPU (8 is the current minimum)
            publicly_accessible=True,
            security_group_ids=[redshift_sg.security_group_id],
            subnet_ids=[subnet.subnet_id for subnet in vpc.public_subnets],
            config_parameters=[
                redshift.CfnWorkgroup.ConfigParameterProperty(
                    parameter_key="max_query_execution_time",
                    parameter_value="300",  # 5 minutes max per query
                ),
            ],
        )
        rs_workgroup.add_dependency(rs_namespace)

        # ------------------------------------------------------------------ #
        # Lambda — Data Generator
        # ------------------------------------------------------------------ #
        data_generator_fn = _lambda.Function(
            self,
            "DataGeneratorFn",
            function_name="portfolio-data-generator",
            runtime=_lambda.Runtime.PYTHON_3_12,
            handler="handler.lambda_handler",
            code=_lambda.Code.from_asset("../lambda/data_generator"),
            timeout=Duration.minutes(10),
            memory_size=1024,
            environment={
                "BUCKET_NAME": data_bucket.bucket_name,
                "DATA_PREFIX": "raw-data/",
            },
            layers=[
                _lambda.LayerVersion.from_layer_version_arn(
                    self,
                    "PandasLayer",
                    # AWS managed Pandas layer for Python 3.12
                    f"arn:aws:lambda:{self.region}:336392948345:layer:AWSSDKPandas-Python312:14",
                ),
            ],
        )

        # Grant S3 write access to the data generator
        data_bucket.grant_write(data_generator_fn)

        # EventBridge schedule — trigger daily at 2 AM UTC
        events.Rule(
            self,
            "DailyDataGenRule",
            rule_name="portfolio-daily-data-gen",
            schedule=events.Schedule.cron(minute="0", hour="2"),
            targets=[targets.LambdaFunction(data_generator_fn)],
        )

        # ------------------------------------------------------------------ #
        # Lambda — Redshift Loader
        # ------------------------------------------------------------------ #
        redshift_loader_fn = _lambda.Function(
            self,
            "RedshiftLoaderFn",
            function_name="portfolio-redshift-loader",
            runtime=_lambda.Runtime.PYTHON_3_12,
            handler="handler.lambda_handler",
            code=_lambda.Code.from_asset("../lambda/redshift_loader"),
            timeout=Duration.minutes(5),
            memory_size=256,
            environment={
                "WORKGROUP_NAME": workgroup_name,
                "DATABASE_NAME": database_name,
                "REDSHIFT_ROLE_ARN": redshift_s3_role.role_arn,
            },
        )

        # Grant Redshift Data API access
        redshift_loader_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=[
                    "redshift-data:ExecuteStatement",
                    "redshift-data:DescribeStatement",
                    "redshift-data:GetStatementResult",
                    "redshift-serverless:GetCredentials",
                ],
                resources=["*"],  # Scoped to workgroup at runtime
            )
        )

        # Trigger on S3 object creation (CSV files in raw-data/ prefix)
        data_bucket.add_event_notification(
            s3.EventType.OBJECT_CREATED,
            s3n.LambdaDestination(redshift_loader_fn),
            s3.NotificationKeyFilter(prefix="raw-data/", suffix=".csv"),
        )

        # ------------------------------------------------------------------ #
        # Outputs
        # ------------------------------------------------------------------ #
        CfnOutput(self, "DataBucketName", value=data_bucket.bucket_name)
        CfnOutput(self, "RedshiftWorkgroup", value=workgroup_name)
        CfnOutput(self, "RedshiftNamespace", value=namespace_name)
        CfnOutput(self, "RedshiftDatabase", value=database_name)
        CfnOutput(self, "RedshiftS3RoleArn", value=redshift_s3_role.role_arn)
        CfnOutput(
            self,
            "RedshiftEndpoint",
            value=f"{workgroup_name}.{self.region}.redshift-serverless.amazonaws.com:5439/{database_name}",
        )
        CfnOutput(self, "SecretArn", value=redshift_secret.secret_arn)
