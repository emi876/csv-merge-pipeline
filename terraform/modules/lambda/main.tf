resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group_name
  retention_in_days = var.retention_in_days
}

resource "null_resource" "lambda_dependencies" {
  provisioner "local-exec" {
    command = "${var.lambda_directory}/${var.lambda_build_script}"
    environment = {
      requirements_path = "${var.lambda_directory}/${var.lambda_requirements_path}"
    }
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.lambda_directory
  output_path = local.lambda_zip_location
  depends_on  = [null_resource.lambda_dependencies]
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      INPUT_BUCKET       = var.input_bucket_name
      OUTPUT_BUCKET      = var.output_bucket_name
      ANXIETY_KEY        = var.anxiety_key
      DEMOGRAPHICS_KEY   = var.demographics_key
      OUTPUT_KEY         = var.output_key
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda]
}