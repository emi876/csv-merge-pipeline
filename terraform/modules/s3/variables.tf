variable "environment" {
  type        = string
  description = "The SDLC environment resources will be deployed into"
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "enable_server_side_encryption" {
  type    = bool
  default = true
}

variable "block_public_acls" {
  type    = bool
  default = true
}

variable "block_public_policy" {
  type    = bool
  default = true
}

variable "ignore_public_acls" {
  type    = bool
  default = true
}

variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "create_bucket_policy" {
  type    = bool
  default = false
}

variable "sse_algorithm" {
  type    = string
  default = "AES256"
}

variable "bucket_name" {
  type        = string
  description = "The name of the s3 bucket"
}
variable "s3_bucket_policy" {
  default = null
}
