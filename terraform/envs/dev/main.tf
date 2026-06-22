provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "raw" {
  bucket = var.raw_bucket_name

  tags = {
    Project     = "weather-data-lake"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_pab" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}