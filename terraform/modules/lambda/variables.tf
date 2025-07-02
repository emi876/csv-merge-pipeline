variable "environment" {
  description = "The environment for the Lambda function (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "retention_in_days" {
  description = "The number of days to retain logs in CloudWatch"
  type        = number
  default     = 7
}

variable "input_bucket_arn" {
  description = "The ARN of the S3 bucket where input files are stored"
  type        = string
}

variable "output_bucket_arn" {
  description = "The ARN of the S3 bucket where output files will be stored"
  type        = string
}

variable "lambda_directory" {
  description = "The directory containing the Lambda function code"
  type        = string
}

variable "lambda_build_script" {
  description = "The script to build the Lambda function"
  type        = string
  default     = "lambda_build.sh"
}

variable "lambda_requirements_path" {
  description = "The path to the requirements file for the Lambda function"
  type        = string
  default     = "requirements.txt"
}

variable "lambda_handler" {
  description = "The handler for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "The runtime for the Lambda function"
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "The memory size for the Lambda function in MB"
  type        = number
  default     = 256
}

variable "input_bucket_name" {
  description = "The name of the S3 bucket where input files are stored"
  type        = string
}

variable "output_bucket_name" {
  description = "The name of the S3 bucket where output files will be stored"
  type        = string
}

variable "anxiety_key" {
  description = "The key for the anxiety data in the output file"
  type        = string
  default     = "SF_HOMELESS_ANXIETY.csv"
}

variable "demographics_key" {
  description = "The key for the demographics data in the output file"
  type        = string
  default     = "SF_HOMELESS_DEMOGRAPHICS.csv"
}

variable "output_key" {
  description = "The key for the output file in the S3 bucket"
  type        = string
  default     = "merged_output.csv"
}

variable "schedule_expression" {
  description = "The schedule expression for the EventBridge rule (e.g., rate(5 minutes), cron(0 12 * * ? *))"
  type        = string
  default     = "rate(30 minutes)"
}