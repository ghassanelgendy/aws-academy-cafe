variable "aws_region" {
  description = "The AWS region for the development environment."
  type        = string
  default     = "us-east-1"
}

variable "prod_region" {
  description = "The AWS region for the production environment."
  type        = string
  default     = "us-west-2"
}

variable "project_prefix" {
  description = "Prefix for all resources created."
  type        = string
  default     = "cafe"
}

variable "instance_type" {
  description = "EC2 instance type for the dev environment."
  type        = string
  default     = "t2.micro"
}

variable "instance_type_prod" {
  description = "EC2 instance type for the prod environment."
  type        = string
  default     = "t2.small"
}

variable "db_user" {
  description = "Database user name."
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "Database name."
  type        = string
  default     = "cafe_db"
}

variable "cafe_zip_url" {
  description = "URL for the cafe application zip file."
  type        = string
  default     = "https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/cafe.zip"
}

variable "db_zip_url" {
  description = "URL for the database schema zip file."
  type        = string
  default     = "https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/db.zip"
}

variable "setup_zip_url" {
  description = "URL for the setup zip file."
  type        = string
  default     = "https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/setup.zip"
}