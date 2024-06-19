output "ecs_cluster_name" {
  value = var.existing_ecs_cluster_arn != "" ? var.existing_ecs_cluster_arn : aws_ecs_cluster.app_cluster[0].name
}

output "ecs_service_name" {
  value = aws_ecs_service.app_service.name
}

output "load_balancer_dns_name" {
  value = aws_lb.app_lb.dns_name
}

output "api_url" {
  value = "API accessible at: https://${aws_route53_record.app_record.fqdn}/epoch"
}
