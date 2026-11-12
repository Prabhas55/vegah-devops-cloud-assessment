# Backups live in the DR region, i.e. outside the failure domain of the primary region.
resource "aws_s3_bucket" "backups" {
  provider = aws.dr
  bucket   = "vegah-dr-backups-${data.aws_caller_identity.current.account_id}-${var.dr_region}"
  tags     = { Project = "vegah-dr" }
}

resource "aws_s3_bucket_versioning" "backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  provider                = aws.dr
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 14
    }
  }
}
