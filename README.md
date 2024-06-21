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
    
    api_url = "API accessible at: https://epoch-time-api.coffee-sandbox.xxxxx.co/epoch"
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

## Terraform plan
```hcl
data.aws_caller_identity.current: Reading...
data.aws_caller_identity.current: Still reading... [10s elapsed]
data.aws_caller_identity.current: Read complete after 10s [id=xxxx]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_ecs_cluster.app_cluster[0] will be created
  + resource "aws_ecs_cluster" "app_cluster" {
      + arn                = (known after apply)
      + capacity_providers = (known after apply)
      + id                 = (known after apply)
      + name               = "epoch-time-api-cluster"
      + tags_all           = (known after apply)
    }

  # aws_ecs_service.app_service will be created
  + resource "aws_ecs_service" "app_service" {
      + cluster                            = (known after apply)
      + deployment_maximum_percent         = 200
      + deployment_minimum_healthy_percent = 100
      + desired_count                      = 1
      + enable_ecs_managed_tags            = false
      + enable_execute_command             = false
      + iam_role                           = (known after apply)
      + id                                 = (known after apply)
      + launch_type                        = "FARGATE"
      + name                               = "epoch-time-api-service"
      + platform_version                   = "1.4.0"
      + scheduling_strategy                = "REPLICA"
      + tags_all                           = (known after apply)
      + task_definition                    = (known after apply)
      + wait_for_steady_state              = false

      + load_balancer {
          + container_name   = "epoch-time-api"
          + container_port   = 5000
          + target_group_arn = (known after apply)
        }

      + network_configuration {
          + assign_public_ip = false
          + security_groups  = (known after apply)
          + subnets          = [
              + "xxxx",
              + "xxxx",
            ]
        }
    }

  # aws_ecs_task_definition.app_task will be created
  + resource "aws_ecs_task_definition" "app_task" {
      + arn                      = (known after apply)
      + container_definitions    = jsonencode(
            [
              + {
                  + essential        = true
                  + image            = "xxxx.dkr.ecr.us-east-2.amazonaws.com/epoch-time-api:latest"
                  + logConfiguration = {
                      + logDriver = "awslogs"
                      + options   = {
                          + awslogs-group         = "/ecs/epoch-time-api"
                          + awslogs-region        = "us-east-2"
                          + awslogs-stream-prefix = "epoch-time-api"
                        }
                    }
                  + name             = "epoch-time-api"
                  + portMappings     = [
                      + {
                          + containerPort = 5000
                          + hostPort      = 5000
                        },
                    ]
                },
            ]
        )
      + cpu                      = "256"
      + execution_role_arn       = (known after apply)
      + family                   = "epoch-time-api-task"
      + id                       = (known after apply)
      + memory                   = "512"
      + network_mode             = "awsvpc"
      + requires_compatibilities = [
          + "FARGATE",
        ]
      + revision                 = (known after apply)
      + skip_destroy             = false
      + tags_all                 = (known after apply)
      + task_role_arn            = (known after apply)
    }

  # aws_iam_role.ecs_task_execution_role[0] will be created
  + resource "aws_iam_role" "ecs_task_execution_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "ecs-tasks.amazonaws.com"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = [
          + "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
          + "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        ]
      + max_session_duration  = 3600
      + name                  = "epoch-time-api-ecs-task-execution-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)
    }

  # aws_iam_role.ecs_task_role[0] will be created
  + resource "aws_iam_role" "ecs_task_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "ecs-tasks.amazonaws.com"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = [
          + "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
          + "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        ]
      + max_session_duration  = 3600
      + name                  = "epoch-time-api-ecs-task-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)
    }

  # aws_lb.app_lb will be created
  + resource "aws_lb" "app_lb" {
      + arn                        = (known after apply)
      + arn_suffix                 = (known after apply)
      + desync_mitigation_mode     = "defensive"
      + dns_name                   = (known after apply)
      + drop_invalid_header_fields = false
      + enable_deletion_protection = false
      + enable_http2               = true
      + enable_waf_fail_open       = false
      + id                         = (known after apply)
      + idle_timeout               = 60
      + internal                   = false
      + ip_address_type            = (known after apply)
      + load_balancer_type         = "application"
      + name                       = "epoch-time-api-lb"
      + security_groups            = (known after apply)
      + subnets                    = [
          + "xxxx",
          + "xxxx",
        ]
      + tags_all                   = (known after apply)
      + vpc_id                     = (known after apply)
      + zone_id                    = (known after apply)
    }

  # aws_lb_listener.http_listener will be created
  + resource "aws_lb_listener" "http_listener" {
      + arn               = (known after apply)
      + id                = (known after apply)
      + load_balancer_arn = (known after apply)
      + port              = 80
      + protocol          = "HTTP"
      + ssl_policy        = (known after apply)
      + tags_all          = (known after apply)

      + default_action {
          + order = (known after apply)
          + type  = "redirect"

          + redirect {
              + host        = "#{host}"
              + path        = "/#{path}"
              + port        = "443"
              + protocol    = "HTTPS"
              + query       = "#{query}"
              + status_code = "HTTP_301"
            }
        }
    }

  # aws_lb_listener.https_listener will be created
  + resource "aws_lb_listener" "https_listener" {
      + arn               = (known after apply)
      + certificate_arn   = "arn:aws:acm:xxxx:certificate/xxxx"
      + id                = (known after apply)
      + load_balancer_arn = (known after apply)
      + port              = 443
      + protocol          = "HTTPS"
      + ssl_policy        = "ELBSecurityPolicy-2016-08"
      + tags_all          = (known after apply)

      + default_action {
          + order            = (known after apply)
          + target_group_arn = (known after apply)
          + type             = "forward"
        }
    }

  # aws_lb_target_group.app_tg will be created
  + resource "aws_lb_target_group" "app_tg" {
      + arn                                = (known after apply)
      + arn_suffix                         = (known after apply)
      + connection_termination             = false
      + deregistration_delay               = "300"
      + id                                 = (known after apply)
      + lambda_multi_value_headers_enabled = false
      + load_balancing_algorithm_type      = (known after apply)
      + name                               = "epoch-time-api-tg"
      + port                               = 5000
      + preserve_client_ip                 = (known after apply)
      + protocol                           = "HTTP"
      + protocol_version                   = (known after apply)
      + proxy_protocol_v2                  = false
      + slow_start                         = 0
      + tags_all                           = (known after apply)
      + target_type                        = "ip"
      + vpc_id                             = "xxxx"

      + health_check {
          + enabled             = true
          + healthy_threshold   = 2
          + interval            = 30
          + matcher             = "200"
          + path                = "/epoch"
          + port                = "traffic-port"
          + protocol            = "HTTP"
          + timeout             = 5
          + unhealthy_threshold = 2
        }
    }

  # aws_route53_record.app_record will be created
  + resource "aws_route53_record" "app_record" {
      + allow_overwrite = (known after apply)
      + fqdn            = (known after apply)
      + id              = (known after apply)
      + name            = "epoch-time-api"
      + type            = "A"
      + zone_id         = "xxxx"

      + alias {
          + evaluate_target_health = true
          + name                   = (known after apply)
          + zone_id                = (known after apply)
        }
    }

  # aws_security_group.ecs_sg[0] will be created
  + resource "aws_security_group" "ecs_sg" {
      + arn                    = (known after apply)
      + description            = "Allow inbound traffic from Load Balancer"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = []
              + description      = ""
              + from_port        = 5000
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = (known after apply)
              + self             = false
              + to_port          = 5000
            },
        ]
      + name                   = "epoch-time-api-ecs-sg"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = "xxxx"
    }

  # aws_security_group.lb_sg[0] will be created
  + resource "aws_security_group" "lb_sg" {
      + arn                    = (known after apply)
      + description            = "Allow HTTP and HTTPS inbound traffic"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 443
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 443
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "epoch-time-api-lb-sg"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = "xxxx"
    }

Plan: 12 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + api_url                = (known after apply)
  + ecs_cluster_name       = "epoch-time-api-cluster"
  + ecs_service_name       = "epoch-time-api-service"
  + load_balancer_dns_name = (known after apply)

```
