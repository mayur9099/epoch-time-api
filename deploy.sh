#!/bin/bash

set -e

function error_exit {
    echo "$1" 1>&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <region> <repo_name>"
    exit 1
fi

REGION=$1
REPO_NAME=$2
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || error_exit "Failed to get AWS account ID. Ensure AWS CLI is configured correctly."

# Build the Docker image
docker build --platform linux/amd64 -t $REPO_NAME .  || error_exit "Docker build failed. Ensure Docker is running and the Dockerfile is correct."

# Authenticate Docker to the ECR registry
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com || error_exit "Docker login to ECR failed. Check your AWS credentials and ECR permissions."

# Tag the Docker image
docker tag ${REPO_NAME}:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest || error_exit "Docker tag failed. Ensure the image name is correct."

# Push the Docker image to ECR
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest || error_exit "Docker push to ECR failed. Ensure the repository exists in ECR."

# Change directory to Terraform configuration
cd terraform || error_exit "Failed to change directory to 'terraform'. Ensure the directory exists."

# Initialize Terraform
terraform init || error_exit "Terraform initialization failed. Ensure Terraform is installed and the configuration files are correct."

# Run a plan
terraform plan || error_exit "Terraform plan failed. Check the Terraform configuration for errors."

# Apply the Terraform configuration
terraform apply -auto-approve || error_exit "Terraform apply failed. Check the Terraform configuration and AWS resources."
