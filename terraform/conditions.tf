resource "aws_s3_bucket" "pre_post_example" {
  bucket = "prepost-example-123456"
  acl    = "private"

  lifecycle {
    prevent_destroy = false
  }

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

resource "aws_route_table" "private_rt_dep" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  depends_on = [aws_nat_gateway.nat]  # explicit dependency
}
