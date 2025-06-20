# The ID of the VPC
output "vpc_id" {
  value = aws_vpc.movies_app_vpc.id
}

# The private dns of mysql ec2
output "mysql_ec2_private_dns" {
  value = aws_instance.mysql_db_ec2.private_dns
}

# The arn of the secret manager
output "secret_manage_arn" {
  value = aws_secretsmanager_secret.mysql_db_secrets.arn
}
