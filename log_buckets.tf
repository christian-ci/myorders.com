data "aws_canonical_user_id" "current" {}

resource "aws_kms_key" "objects" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

resource "aws_iam_role" "s3rolelogs" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3rolelogs.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name_logs}",
    ]
  }
}

module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = ">=1.21.0"

  bucket                         = "${local.bucket_name_logs}"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  attach_elb_log_delivery_policy = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "cloudwatch_log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = ">=1.21.0"

  bucket = "${local.bucket_name_cloudwatch}"
  acl    = null
  grant = [{
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = data.aws_canonical_user_id.current.id
    }, {
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"    
  }]
  force_destroy = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}