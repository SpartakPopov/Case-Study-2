provider "aws" {
  region  = "eu-central-1"
  profile = "innovatech"
}

data "aws_caller_identity" "current" {} // for reading AWS account id


resource "aws_s3_bucket" "tfstate" {
  bucket = "innovatech-tfstate-${data.aws_caller_identity.current.account_id}" //uses account number for unique bucket name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" { // for encruption of state
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" { // keeping state private
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tfstate" { // for keeping old versions if needed to revert
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_name" { //printing bucket name if needed 
  value = aws_s3_bucket.tfstate.bucket
}
