# ─────────────────────────────────────────────
# S3 Buckets
# ─────────────────────────────────────────────

import {
  to = aws_s3_bucket.rdl_staging
  id = "boohoo-dns-rdl-staging"
}

import {
  to = aws_s3_bucket.terraform_state
  id = "boohoo-terraform-state-332779204498"
}

resource "aws_s3_bucket" "rdl_staging" {
  bucket = "boohoo-dns-rdl-staging"
}

resource "aws_s3_bucket_versioning" "rdl_staging" {
  bucket = aws_s3_bucket.rdl_staging.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rdl_staging" {
  bucket = aws_s3_bucket.rdl_staging.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "boohoo-terraform-state-332779204498"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─────────────────────────────────────────────
# Parquet Export Bucket
# ─────────────────────────────────────────────
# Daily UNLOAD from Redshift writes Parquet files
# here, organised by layer/model/date. DuckDB apps
# read from this bucket for dashboard analytics.

resource "aws_s3_bucket" "parquet_exports" {
  bucket = "boohoo-data-quality-staging"

  tags = {
    Name = "boohoo-data-quality-staging"
    Purpose = "DuckDB dashboard data source"
  }
}

resource "aws_s3_bucket_versioning" "parquet_exports" {
  bucket = aws_s3_bucket.parquet_exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "parquet_exports" {
  bucket = aws_s3_bucket.parquet_exports.id

  rule {
    id     = "retain-30-days"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }
  }

  rule {
    id     = "archive-test-results"
    status = "Enabled"
    filter {
      prefix = "tests/"
    }
    transition {
      days          = 7
      storage_class = "GLACIER"
    }
    expiration {
      days = 90
    }
  }
}

# Bucket policy: allow Redshift role to write
resource "aws_s3_bucket_policy" "parquet_exports" {
  bucket = aws_s3_bucket.parquet_exports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRedshiftUnload"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.redshift_s3_role.arn }
        Action    = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource  = [
          aws_s3_bucket.parquet_exports.arn,
          "${aws_s3_bucket.parquet_exports.arn}/*"
        ]
      }
    ]
  })
}
