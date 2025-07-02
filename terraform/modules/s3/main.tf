###########
# S3 Bucket
###########
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  tags = merge(
    {
      "Name" = local.bucket_name
    },
    local.tags
  )
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.enable_versioning == true ? 1 : 0

  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_server_side_encryption == true ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  depends_on = [
    aws_s3_bucket.main
  ]
}
