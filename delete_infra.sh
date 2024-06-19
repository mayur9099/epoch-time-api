#!/bin/bash

function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Change directory to Terraform configuration
cd terraform || error_exit "Failed to change directory to 'terraform'. Ensure the directory exists."

# Run Terraform destroy
terraform destroy -auto-approve || error_exit "Terraform destroy failed. Check the Terraform configuration and AWS resources."
