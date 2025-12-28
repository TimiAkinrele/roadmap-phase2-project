# 1. The S3 Bucket for State Storage
resource "aws_s3_bucket" "tf_state_bucket" {
  # Unique buckent name
  bucket = "terraform-state-devsecops-admin-timi-unique-1"

  # Prevents accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform Remote State"
  }
}

# 2. Enable Versioning (Recovery)
resource "aws_s3_bucket_versioning" "tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable Encryption (Security)
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_security" {
  bucket = aws_s3_bucket.tf_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. The DynamoDB Table for Locking
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Prevent accidental deletion of this table
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}