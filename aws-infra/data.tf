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

data "aws_iam_policy_document" "mysql_ec2_secrets_policy_doc" {
  statement {
    sid     = "AllowSecretsManagerAccess"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_secretsmanager_secret.mysql_db_secrets.arn]
  }
}

data "aws_iam_policy_document" "backend_ec2_policy_doc" {
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
  statement {
    sid    = "AllowBedrockModelInvocation"
    effect = "Allow"

    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:ap-south-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"]
  }
  statement {
    sid    = "AllowS3ObjectWriteDelete"
    effect = "Allow"

    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.movies_app_bucket.arn}/${var.s3_images_prefix}/*"]
  }
}
