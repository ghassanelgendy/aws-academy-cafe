terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

# -------------------------------
# Providers (primary + DR region)
# -------------------------------
provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# -------------------------------
# Primary S3 bucket
# -------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_prefix}-website"
  force_destroy = true
  tags = {
    Project = "Cafe"
    Purpose = "Static Website"
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = 30
    }
  }
}

# -------------------------------
# Disaster Recovery (DR) bucket
# -------------------------------
resource "aws_s3_bucket" "replica" {
  bucket   = "${var.project_prefix}-dr"
  provider = aws.dr
  force_destroy = true
  tags = {
    Project = "Cafe"
    Purpose = "Disaster Recovery"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  bucket   = aws_s3_bucket.replica.id
  provider = aws.dr
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------------
# Replication configuration
# -------------------------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [
    aws_s3_bucket_versioning.website,
    aws_s3_bucket_versioning.replica
  ]

  bucket = aws_s3_bucket.website.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}

# -------------------------------
# IAM role for replication
# -------------------------------
resource "aws_iam_role" "replication_role" {
  name = "${var.project_prefix}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
 })
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "${var.project_prefix}-replication-policy"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.website.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectVersionTagging"
        ]
        Resource = ["${aws_s3_bucket.website.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = ["${aws_s3_bucket.replica.arn}/*"]
      }
    ]
  })
}

# -------------------------------
# Upload website files
# -------------------------------
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/website", "**")

  bucket = aws_s3_bucket.website.id
  key    = each.value
  source = "${path.module}/website/${each.value}"
  etag   = filemd5("${path.module}/website/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
  }, regex("\\.([^.]+)$", each.value)[0], "application/octet-stream")
}
# -------------------------------
# Public bucket policy (for website hosting)
# -------------------------------
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.website_public_access]
}

# -------------------------------
# Disable Block Public Access for Website Bucket
# -------------------------------
resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

