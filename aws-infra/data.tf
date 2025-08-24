# S3 bucket policy for public read access to movie images
data "aws_iam_policy_document" "allow_get_s3_images_policy" {
  statement {
    sid = "AllowS3ObjectGetAccess"

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::${var.bucket_name}/${var.s3_images_prefix}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

# Trust policy allowing EC2 instances to assume IAM roles
data "aws_iam_policy_document" "ec2_assume_role_policy_doc" {
  statement {
    sid     = "AssumeRoleAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Policy for MySQL EC2 instance to retrieve database credentials
data "aws_iam_policy_document" "mysql_ec2_secrets_policy_doc" {
  statement {
    sid     = "AllowSecretsManagerAccess"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_secretsmanager_secret.mysql_db_secrets.arn]
  }
}

# Comprehensive policy for backend EC2 instance permissions
data "aws_iam_policy_document" "backend_ec2_policy_doc" {
  # Allow access to database credentials
  statement {
    sid    = "AllowSecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.mysql_db_secrets.arn
    ]
  }
  
  # Allow AI model invocation for movie recommendations/analysis
  statement {
    sid    = "AllowBedrockModelInvocation"
    effect = "Allow"

    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:ap-south-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"]
  }
  
  # Allow backend to upload/delete movie images
  statement {
    sid    = "AllowS3ObjectWriteDelete"
    effect = "Allow"

    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.movies_app_bucket.arn}/${var.s3_images_prefix}/*"]
  }
}
