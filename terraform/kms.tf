resource "aws_kms_key" "example" {
  description             = "TF-managed KMS key for examples"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Allow administration of the key",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_kms_alias" "example_alias" {
  name          = "alias/my-example-key"
  target_key_id = aws_kms_key.example.key_id
}

data "aws_caller_identity" "current" {}
