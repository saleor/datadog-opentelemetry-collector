output "vpc_endpoint_service_name" {
  value = aws_vpc_endpoint_service.otlp_privatelink.service_name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}
