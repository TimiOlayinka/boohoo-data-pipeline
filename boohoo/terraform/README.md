# Boohoo Terraform Infrastructure

This directory contains all Infrastructure as Code (IaC) for the Boohoo Data Pipeline.

## Resources Managed

| File | Resources |
|------|-----------|
| `main.tf` | AWS provider, S3 remote backend |
| `iam.tf` | Lambda execution role (`BoohooDataGeneratorRole`) |
| `lambdas.tf` | 9 Lambda micro-services for data generation |
| `eventbridge.tf` | 9 daily cron rules + Lambda permissions |
| `s3.tf` | Data lake bucket with versioning & lifecycle |
| `redshift.tf` | Redshift Serverless namespace & workgroup |
| `variables.tf` | Input variables (e.g. Redshift password) |
| `outputs.tf` | Resource references for downstream use |

## Usage

```bash
# Initialise Terraform (downloads providers, connects to S3 backend)
terraform init

# Preview what will change
terraform plan

# Apply changes to AWS
terraform apply

# Destroy all resources (use with caution)
terraform destroy
```

## Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `redshift_master_password` | Redshift admin password | *(required)* |
| `redshift_master_username` | Redshift admin username | `admin` |
| `environment` | Environment tag | `production` |

Pass variables via CLI:
```bash
terraform apply -var="redshift_master_password=YourSecurePassword123!"
```

Or via a `terraform.tfvars` file (do **not** commit this file):
```hcl
redshift_master_password = "YourSecurePassword123!"
```
