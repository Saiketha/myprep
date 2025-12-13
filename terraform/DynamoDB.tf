variable "dynamo_table_name" { default = "example-table" }

resource "aws_kms_key" "ddb" {
  description = "KMS key for DynamoDB encryption (example)"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

resource "aws_iam_role" "ddb_role" {
  name = "ddb-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "dynamodb.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ddb_role_policy" {
  role = aws_iam_role.ddb_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["kms:Encrypt","kms:Decrypt","kms:GenerateDataKey*"],
        Resource = aws_kms_key.ddb.arn
      }
    ]
  })
}

resource "aws_dynamodb_table" "example" {
  name         = var.dynamo_table_name
  billing_mode = "PAY_PER_REQUEST"  # on-demand. Use PROVISIONED with read_capacity/write_capacity if desired
  hash_key     = "pk"
  range_key    = "sk"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  attribute {
    name = "gsi1pk"
    type = "S"
  }
  attribute {
    name = "lsi1sk"
    type = "S"
  }

  # Local Secondary Index (LSI) - must have same hash key (pk)
  local_secondary_index {
    name            = "lsi-by-lsi1sk"
    range_key       = "lsi1sk"
    projection_type = "ALL"
  }

  # Global Secondary Index (GSI)
  global_secondary_index {
    name               = "gsi1"
    hash_key           = "gsi1pk"
    range_key          = "sk"
    projection_type    = "keys_only"
    # If PROVISIONED, set read_capacity/write_capacity here
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.ddb.arn
  }

  tags = { Environment = "dev" }
}
