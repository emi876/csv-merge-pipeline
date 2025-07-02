variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The SDLC environment resources will be deployed into"
  type        = string
  default     = "dev"
}