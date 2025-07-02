locals {
  bucket_name = "${var.bucket_name}-${var.environment}"
  tags = {
    Terraform   = true
    Environment = var.environment
  }
}
