# Epoch Time API

## Description
This project sets up a simple API endpoint that returns the current epoch time in JSON format. The API is deployed on AWS using Docker, ECS, and Terraform. The setup allows for optional use of existing AWS resources for ECS clusters, IAM roles, CloudWatch Log Groups, Security Groups, and ACM certificates.

## Prerequisites
- AWS CLI
- Terraform
- Docker

## Assumptions
- You have an AWS account with the necessary permissions to create and manage AWS resources.
- You have an existing VPC with both public and private subnets.
- The VPC has an Internet Gateway (IGW) attached for public subnets and a NAT Gateway for private subnets.
- You have a registered domain name and a Route 53 hosted zone.
- You already have an ECR repo created, where you will use this code to push image

## Directory Structure
```sh
epoch-time-api/
├── app.py
├── Dockerfile
├── deploy.sh
├── terraform/
│ ├── main.tf
│ ├── providers.tf
│ ├── variables.tf
├── ReadMe.md
```

## Setup Instructions

### Step-by-Step Setup

1. **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd <repository-name>
    ```

2. **Configure AWS credentials:**
    Ensure you have AWS credentials configured. You can set up your credentials using:
    ```sh
    aws configure
    ```

3. **Update `variables.tf` with your AWS configuration:**
    Note: This is the most important step, please update variables.tf in accordance to your Infra
    Edit the `terraform/variables.tf` file to include your VPC ID, subnets, domain name, Route 53 hosted zone ID, and other configuration details.

5. **Build,push the Docker image and create the infrastructure on AWS:**

    ```sh
    chmod +x deploy.sh
    ./deploy.sh <region> <ecr_repo_name>
    ```

    terraform outouts after successful apply:

   ```sh
    Outputs:
    
    api_url = "API accessible at: https://epoch-time-api.coffee-sandbox.medcrypt.co/epoch"
    ecs_cluster_name = "epoch-time-api-cluster"
    ecs_service_name = "epoch-time-api-service"
    load_balancer_dns_name = "epoch-time-api-lb-2101495011.us-east-2.elb.amazonaws.com"
    ```

6. **Access the API:**
    - The API will be accessible at `https://<your-route-53-dns-record-name>/epoch`

## Tools and Versions
- **AWS CLI**: 2.x
- **Terraform**: 1.x
- **Docker**: 20.x
- **Python**: 3.8
- **Flask**: 2.0.3

## Infrastructure Details
- **Load Balancer (Public Subnets)**: The load balancer is deployed in public subnets and routes traffic to ECS tasks in private subnets. It listens on both HTTP (port 80) and HTTPS (port 443) and redirects HTTP traffic to HTTPS.
- **ECS Tasks (Private Subnets)**: The Docker containers running the Flask application are deployed in private subnets, enhancing security.
- **Security Groups**: Security groups are configured to allow traffic from the load balancer to the ECS tasks and to allow the load balancer to be accessed publicly.
- **IAM Roles**: IAM roles are configured to allow ECS tasks to pull images from ECR and to interact with other AWS services securely.
- **DNS Record**: A DNS record is created in Route 53 to map the domain name to the Load Balancer's DNS name.

## Optional Existing Resources
This setup allows you to use existing AWS resources by providing their ARNs or IDs in the `variables.tf` file. The resources that can be optionally used include:
- Existing ACM certificate
- Existing ECS cluster
- Existing IAM roles for ECS tasks
- Existing CloudWatch Log Group
- Existing security groups for the load balancer and ECS tasks

## HTTPS Implementation
- HTTPS is implemented using AWS Certificate Manager (ACM) and the load balancer is configured to listen on port 443.

## Destroying the Infrastructure
To destroy the infrastructure created by Terraform, you can run the provided `delete_infra.sh` script.

### Steps to Destroy Infrastructure

1. **Make the script executable:**
    ```sh
    chmod +x delete_infra.sh
    ```

2. **Run the script:**
    ```sh
    ./delete_infra.sh
    ```

## Troubleshooting
- **AWS Credentials**: Ensure all AWS credentials and permissions are correctly configured.
- **Docker Issues**: Verify Docker is running and the Dockerfile is correct.
- **Terraform Issues**: Check the Terraform configuration for errors and ensure Terraform is properly installed.
- **AWS Resources**: Verify that all necessary AWS resources (VPC, subnets, security groups) are in place and properly configured.

By following these instructions, you should be able to deploy the epoch time API successfully with HTTPS enabled.

## Testing via UI and Curl:

```sh
curl https://<route43-dns-record-name>/epoch
```
<img width="1066" alt="Screenshot 2024-06-19 at 3 17 04 PM" src="https://github.com/mayur9099/epoch-time-api/assets/16243940/61a4f59a-68c7-454d-a5ab-bdb633c43428">

<img width="1047" alt="Screenshot 2024-06-19 at 3 17 35 PM" src="https://github.com/mayur9099/epoch-time-api/assets/16243940/3bbef002-3f0a-484c-95cf-fb29204f44fa">


