data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "s3_role" {
  name = "Policy-S3-access"
  description = "Policy for role S3 access"
  policy = jsonencode (
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3Policy",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",                
            ],
            "Resource": [
                "arn:aws:s3:::${local.bucket_name_private}",
                "arn:aws:s3:::${local.bucket_name_private}/*",
            ]
        }
    ]
}
  )

}

resource "aws_iam_role" "s3_role_access" {
  name = "ec2-s3-role-access"
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.s3_role.arn]
}