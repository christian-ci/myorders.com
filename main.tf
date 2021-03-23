provider "aws" {
    region = "us-east-2"
    shared_credentials_file = "/home/christian/.aws/credentials"
    }
resource "random_string" "random" {
  length = 5
  special = true
  override_special = "-"
  upper = false
}    
locals {
  bucket_name_private = "s3-private-uploads-${random_string.random.result}"
  bucket_name_logs = "myorders-logs-${random_string.random.result}"
  bucket_name_cloudwatch = "cloudwatch-logs-${random_string.random.result}"
  }