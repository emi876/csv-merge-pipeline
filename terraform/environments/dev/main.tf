module "input_bucket" {
  source      = "../../modules/s3"
  bucket_name = "emi-csv-input"
  environment = var.environment
}

module "output_bucket" {
  source      = "../../modules/s3"
  bucket_name = "emi-csv-output"
  environment = var.environment
}

module "lambda" {
  source = "../../modules/lambda"

  # Required — no defaults
  input_bucket_name  = module.input_bucket.s3_bucket_name
  input_bucket_arn   = module.input_bucket.s3_bucket_arn
  output_bucket_name = module.output_bucket.s3_bucket_name
  output_bucket_arn  = module.output_bucket.s3_bucket_arn

  lambda_directory = "${path.module}/../../lambda/csv_lambda"
}
