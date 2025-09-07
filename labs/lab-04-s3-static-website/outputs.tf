# -------------------------------
# Outputs
# -------------------------------

output "website_bucket_name" {
  description = "Primary S3 bucket name for the static website"
  value       = aws_s3_bucket.website.bucket
}

output "replica_bucket_name" {
  description = "Secondary S3 bucket name (DR region)"
  value       = aws_s3_bucket.replica.bucket
}

output "static_website_url" {
  description = "URL of the hosted static website"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

