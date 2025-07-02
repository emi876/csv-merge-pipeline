################
# IAM For Lambda
################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    sid    = "AllowLambdaToWriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda.arn}:*"
    ]
  }

  statement {
    sid    = "AllowLambdaToAccessS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      var.input_bucket_arn,
      "${var.input_bucket_arn}/*",
      var.output_bucket_arn,
      "${var.output_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "csv-merge-lambda-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "IAM role for CSV Merge Lambda function in ${var.environment} environment"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "csv-merge-lambda-policy-${var.environment}"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}
