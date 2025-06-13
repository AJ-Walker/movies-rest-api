// The ID of the VPC
output "vpc_id" {
  value = aws_vpc.movies_app_vpc.id
}

// The public ip of ec2
# output "public_ip" {
#   value = aws_instance.mysql_db_ec2.public_ip
# }

// The public ip of ec2
output "public_ip" {
  value = aws_instance.go_backend_ec2.public_ip
}

// The arn of the secret manager
output "secret_manage_arn" {
  value = aws_secretsmanager_secret.mysql_db_secrets.arn
}
