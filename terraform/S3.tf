resource "aws_s3_bucket" "site" {
  bucket = "my-static-site-example-123456"   # replace with unique bucket name
  acl    = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  tags = { Environment = "dev" }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Upload index.html from local path
resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.site.id
  key    = "index.html"
  source = "files/index.html"   # local path; create this file
  acl    = "public-read"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "styles" {
  bucket = aws_s3_bucket.site.id
  key    = "css.html"           # per request: "css.html"
  source = "files/css.html"     # local path; create this file
  acl    = "public-read"
  content_type = "text/html"
}
