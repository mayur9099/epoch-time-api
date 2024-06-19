# NOTE: These are my defaults, Please override with yours, in accordance with your AWS env

variable "region" {
  description = "The AWS region to deploy in"
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "The VPC ID to deploy into"
  default = "vpc-07156ee372714c64e"
}

variable "app_subnets" {
  description = "A list of private subnets to deploy containers into"
  type        = list(string)
  default = ["subnet-0d96a08289af52d26","subnet-01f64415c6b1c40e8"]
}

variable "app_name" {
  description = "The name of the application"
  default     = "epoch-time-api"
}

variable "lb_public_subnets" {
  description = "The public subnets for the load balancer"
  type        = list(string)
  default     = ["subnet-0c083c6a72e5a238c", "subnet-0648ae8f9ca4193fe"]
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository to use. If not provided, defaults to the application name."
  type        = string
  default     = ""
}

variable "health_check_config" {
  description = "The health check configuration"
  type = map(any)
  default = {
    path                = "/epoch"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

###### You can either create a Cert or use already existing one###
variable "acm_cert_domain_name" {
  description = "The domain name for the SSL certificate"
  type        = string
  default     = "epoch-time-api.coffee-sandbox.medcrypt.co"
}

variable "existing_cert_arn" {
  description = "The ARN of an existing ACM certificate"
  type        = string
  default     = "arn:aws:acm:us-east-2:432684854155:certificate/29cd5dc7-c222-4da1-9a78-fcc95d36125e"
}
############ ACM ################

variable "dns_record_name" {
  description = "The domain name for the SSL certificate"
  type        = string
  default     = "epoch-time-api"
}

variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID"
  type        = string
  default     = "Z0868847ZD5VKHNCYBDG"
}

###### You can reuse existing ecs cluster, otherise code will create one #######
variable "existing_ecs_cluster_arn" {
  description = "The ARN of an existing ECS cluster"
  type        = string
  default     = ""
}

###### You can reuse existing ecs role, otherise code will create one #######
variable "existing_task_execution_role_arn" {
  description = "The ARN of an existing IAM role for ECS task execution"
  type        = string
  default     = ""
}

variable "existing_task_role_arn" {
  description = "The ARN of an existing IAM role for ECS task"
  type        = string
  default     = ""
}
############ IAM ###################


#### if you need to re use already existing log group, other wise, the code will create one####
variable "existing_log_group_name" {
  description = "The name of an existing CloudWatch Log Group"
  type        = string
  default     = "/ecs/epoch-time-api"
}

### if you want to re use already existing SG's, if not it'll create one for you#####
variable "existing_lb_sg_id" {
  description = "The ID of an existing security group for the load balancer"
  type        = string
  default     = ""
}

variable "existing_ecs_sg_id" {
  description = "The ID of an existing security group for ECS tasks"
  type        = string
  default     = ""
}
