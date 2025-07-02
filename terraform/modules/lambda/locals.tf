locals {
  account_id            = data.aws_caller_identity.current.account_id
  region                = data.aws_caller_identity.current.id
  lambda_name           = "csv-merge-lambda-${var.environment}"
  lambda_log_group_name = "/aws/lambda/${local.lambda_name}"
  lambda_zip_location   = "${var.lambda_directory}/lambda_function.zip"
}