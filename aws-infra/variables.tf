variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (Dev, Staging, Prod)"
  type        = string
  default     = "Dev"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "movies-app"
}

variable "bucket_name" {
  description = "S3 bucket name for storing movie images"
  type        = string
  default     = "movies-app-data"
}

variable "s3_images_prefix" {
  description = "S3 folder prefix for movie images"
  type        = string
  default     = "images"
}

variable "local_images_folder" {
  description = "Local directory containing movie images to upload"
  type        = string
  default     = "images"
}

variable "availability_zone_1a" {
  description = "Primary availability zone for subnets and instances"
  type        = string
  default     = "ap-south-1a"
}

variable "availability_zone_1b" {
  description = "Secondary availability zone for ALB high availability"
  type        = string
  default     = "ap-south-1b"
}

variable "my_ip" {
  description = "Your public IP address for secure access"
  type        = string
}

variable "database_name" {
  description = "MySQL database name for the movies application"
  type        = string
  default     = "movies_db"
}

variable "database_user" {
  description = "MySQL application user for database access"
  type        = string
  default     = "abhay"
}

variable "mysql_root_user_password" {
  description = "MySQL root user password (stored in Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "mysql_abhay_user_password" {
  description = "MySQL application user password (stored in Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "repo_url" {
  description = "GitHub repository URL containing the Go backend source code"
  type        = string
  default     = "https://github.com/AJ-Walker/movies-rest-api"
}

variable "repo_name" {
  description = "Repository name for cloning and deployment"
  type        = string
  default     = "movies-rest-api"
}
