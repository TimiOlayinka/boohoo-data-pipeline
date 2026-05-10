# ─────────────────────────────────────────────
# S3 Buckets
# ─────────────────────────────────────────────

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
