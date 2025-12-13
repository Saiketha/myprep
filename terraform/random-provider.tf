terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "my-tfstate-bucket" 
    key            = "random-s3-example/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"  
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ✅ Generate a random string for uniqueness
resource "random_string" "suffix" {
  length  = 6
}

# ✅ Create an S3 bucket using the random suffix
resource "aws_s3_bucket" "example" {
  bucket = "my-random-bucket-${random_string.suffix.result}"
  acl    = "private"

  tags = {
    Name        = "RandomBucket"
    Environment = "dev"
  }
}

# ✅ Optional: upload an object to the bucket
resource "aws_s3_object" "example_object" {
  bucket       = aws_s3_bucket.example.id
  key          = "hello.txt"
  content      = "Hello from Terraform + random!"
  content_type = "text/plain"
}
