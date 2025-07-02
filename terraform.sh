#!/bin/bash

set -eo pipefail

# Function to display usage instructions
display_usage() {
    echo "Usage: $0 <environment> <action> [module_target]"
    echo "  <environment>   - The environment (dev, stage, prod)"
    echo "  <action>        - The action (plan, apply, destroy)"
    echo "  [module_target] - Optional: The module target (e.g., module.vpc)"
    exit 1
}

# Function to validate environment and action arguments
validate_arguments() {
    valid_environments=("dev" "stage" "prod")
    valid_actions=("plan" "apply" "destroy")

    if ! [[ " ${valid_environments[@]} " =~ " $1 " ]]; then
        echo "Error: Invalid environment. Use dev, stage, or prod."
        display_usage
    fi

    if ! [[ " ${valid_actions[@]} " =~ " $2 " ]]; then
        echo "Error: Invalid action. Use plan, apply, or destroy."
        display_usage
    fi
}

# Load the configuration values for the S3 backend based on the environment argument
load_s3_config() {
    local config_file="./terraform/environments/$1/$1.conf"
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        echo "Error: Configuration file not found: $config_file"
        exit 1
    fi
}

# Create an S3 bucket if it does not exist
create_s3_bucket() {
    if ! aws s3api head-bucket --bucket $bucket --region $region > /dev/null 2>&1; then
        echo "Creating S3 bucket $bucket"
        if ! aws s3 mb s3://$bucket --region $region; then
            echo "Failed to create S3 bucket: $bucket"
            exit 1
        fi
    else
        echo "S3 bucket $bucket already exists"
    fi
}

# Create a DynamoDB table if it does not exist
create_dynamodb_table() {
    if aws dynamodb describe-table --table-name ${dynamodb_table} --region ${region} > /dev/null 2>&1; then
        echo "DynamoDB Table $dynamodb_table already exists"
    else
        echo "Creating DynamoDB Table $dynamodb_table"
        aws dynamodb create-table \
            --table-name $dynamodb_table \
            --region $region \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
    fi
}

# Initialize Terraform providers and apply the specified Terraform action with the chosen var file
terraform_action() {
    cd ./terraform/environments/$1
    rm -rf .terraform
    rm -rf .terraform.lock.hcl

    terraform init -backend-config="$1.conf" -input=false
    terraform fmt --recursive
    terraform validate

    tfvars_file="$1.tfvars"
    if [ -f "$tfvars_file" ]; then
        echo "Using variable file: $tfvars_file"
        tfvars_arg="-var-file=$tfvars_file"
    else
        echo "No $tfvars_file found — continuing without it"
        tfvars_arg=""
    fi

    if [ "$2" == "plan" ]; then
        terraform plan $tfvars_arg ${3:+-target=$3}
    elif [ "$2" == "apply" ]; then
        export TF_CLI_ARGS="-auto-approve"
        terraform apply $tfvars_arg -auto-approve ${3:+-target=$3}
    elif [ "$2" == "destroy" ]; then
        export TF_CLI_ARGS="-auto-approve"
        terraform destroy $tfvars_arg -auto-approve ${3:+-target=$3}
    fi
}

# Main script logic
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    display_usage
fi

validate_arguments "$1" "$2"
load_s3_config "$1"
create_s3_bucket
create_dynamodb_table
terraform_action "$1" "$2" "$3"
