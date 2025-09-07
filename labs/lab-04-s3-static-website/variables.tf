# variables.tf

variable "aws_region" {
  description = "Primary AWS region for the static website bucket"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Secondary AWS region for disaster recovery replication"
  type        = string
  default     = "us-west-2"
}

variable "project_prefix" {
  description = "Prefix used for naming resources (must be globally unique for S3 buckets)"
  type        = string
  default     = "cafe-pr0jeeu-2025-aws-academy"
}

