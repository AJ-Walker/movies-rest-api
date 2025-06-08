data "aws_iam_policy_document" "allow_get_s3_images_policy" {
  statement {
    sid = "1"

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
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_policy_doc" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_secretsmanager_secret.mysql_db_secrets.arn]
  }
}
