# ─────────────────────────────────────────────
# IAM Roles
# ─────────────────────────────────────────────

data "aws_iam_role" "lambda_exec_role" {
  name = "HNBDataGeneratorRole"
}

# ─────────────────────────────────────────────
# Redshift S3 Access Role
# ─────────────────────────────────────────────
# Allows Redshift Serverless to UNLOAD data to S3
# as Parquet files for the DuckDB dashboard apps.

resource "aws_iam_role" "redshift_s3_role" {
  name = "HNBRedshiftS3UnloadRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "redshift_s3_policy" {
  name = "RedshiftS3UnloadPolicy"
  role = aws_iam_role.redshift_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadWriteParquet"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::hnb-data-quality-staging",
          "arn:aws:s3:::hnb-data-quality-staging/*",
          "arn:aws:s3:::hnb-dns-rdl-staging",
          "arn:aws:s3:::hnb-dns-rdl-staging/*"
        ]
      }
    ]
  })
}
