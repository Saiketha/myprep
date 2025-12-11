resource "aws_s3_bucket" "pre_post_example" {
  bucket = "prepost-example-123456"
  acl    = "private"

  lifecycle {
    prevent_destroy = false
  }

  # Precondition: ensure bucket name follows pattern
  lifecycle_rule {
    id = "tmp" # not related; example for structure
  }

  dynamic "object_lock_configuration" {
    for_each = []
    content {}
  }

  # Terraform 1.2+ precondition/postcondition use `validation` style within resources:
  # NOTE: precondition/postcondition blocks exist for resource and module blocks in TF >=1.2
  # Example (syntactic form):
  precondition {
    condition     = length(aws_s3_bucket.pre_post_example.bucket) > 5
    error_message = "Bucket name must be longer than 5 chars"
  }

  # postcondition: after creation ensure versioning disabled (example)
  postcondition {
    condition     = aws_s3_bucket.pre_post_example.acl == "private"
    error_message = "Bucket acl must be private"
  }
}

# depends_on usage example: ensure nat created before private route table
resource "aws_route_table" "private_rt_dep" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  depends_on = [aws_nat_gateway.nat]  # explicit dependency
}
