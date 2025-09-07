# ============================================================
# Terraform configuration for: lab-04-s3-static-website
# Description: Reimplementation of AWS Academy Café Challenge Lab
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# TODO: Add resources for lab-04-s3-static-website
