# IAM policy documents (examples)
data "aws_iam_policy_document" "s3_policy_doc" {
  statement {
    actions = ["s3:GetObject","s3:PutObject","s3:ListBucket"]
    resources = [
      "arn:aws:s3:::my-static-site-example-123456",
      "arn:aws:s3:::my-static-site-example-123456/*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "example-s3-policy"
  policy = data.aws_iam_policy_document.s3_policy_doc.json
}

data "aws_iam_policy_document" "kms_policy_doc" {
  statement {
    actions = ["kms:Encrypt","kms:Decrypt","kms:GenerateDataKey"]
    resources = ["*"]
    effect = "Allow"
  }
}
resource "aws_iam_policy" "kms_policy" { name = "example-kms-policy"; policy = data.aws_iam_policy_document.kms_policy_doc.json }

data "aws_iam_policy_document" "sm_policy_doc" {
  statement {
    actions   = ["secretsmanager:GetSecretValue","secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.example.arn]
  }
}
resource "aws_iam_policy" "sm_policy" { name = "example-sm-policy"; policy = data.aws_iam_policy_document.sm_policy_doc.json }

data "aws_iam_policy_document" "ddb_policy_doc" {
  statement {
    actions = ["dynamodb:Query","dynamodb:GetItem","dynamodb:PutItem"]
    resources = [aws_dynamodb_table.example.arn]
  }
}
resource "aws_iam_policy" "ddb_policy" { name = "example-ddb-policy"; policy = data.aws_iam_policy_document.ddb_policy_doc.json }

# Role that can be assumed (AssumeRole)
resource "aws_iam_role" "assumable_role" {
  name = "example-assumable-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { AWS = "arn:aws:iam::ACCOUNT_ID:role/some-trusted-role" }, # who can assume
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.assumable_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}
resource "aws_iam_role_policy_attachment" "attach_kms" {
  role       = aws_iam_role.assumable_role.name
  policy_arn = aws_iam_policy.kms_policy.arn
}
resource "aws_iam_role_policy_attachment" "attach_sm" {
  role       = aws_iam_role.assumable_role.name
  policy_arn = aws_iam_policy.sm_policy.arn
}
resource "aws_iam_role_policy_attachment" "attach_ddb" {
  role       = aws_iam_role.assumable_role.name
  policy_arn = aws_iam_policy.ddb_policy.arn
}
