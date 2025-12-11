resource "aws_secretsmanager_secret" "example" {
  name        = "example-secret"
  description = "Example secret for app"
  kms_key_id  = aws_kms_key.example.arn  # optional: encrypt using KMS key above
}

resource "aws_secretsmanager_secret_version" "example_version" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "appuser"
    password = "changeme"   # replace; consider random_password resource instead
  })
}

# Resource policy granting another account or role access (optional)
resource "aws_secretsmanager_secret_policy" "example_policy" {
  secret_arn = aws_secretsmanager_secret.example.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCrossAccountRead"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::ACCOUNT_B_ID:role/SomeRole"
        }
        Action    = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource  = "*"
      }
    ]
  })
}
