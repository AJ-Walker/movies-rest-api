# VPC identifier for reference by other resources
output "vpc_id" {
  description = "ID of the main VPC hosting the movies application"
  value       = aws_vpc.movies_app_vpc.id
}

# MySQL database connection endpoint
output "mysql_ec2_private_dns" {
  description = "Private DNS name of the MySQL database instance"
  value       = aws_instance.mysql_db_ec2.private_dns
}

# Secrets Manager ARN for credential retrieval
output "secret_manager_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.mysql_db_secrets.arn
}

# Application Load Balancer public endpoint
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer for accessing the movies API"
  value       = aws_lb.movies_app_alb.dns_name
}
