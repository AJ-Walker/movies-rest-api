variable "aws_region" {
  description = "The aws region"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "AWS s3 bucket name"
  type        = string
  default     = "movies-app-data"
}

variable "s3_images_prefix" {
  description = "AWS s3 images folder for the image"
  type        = string
  default     = "images"
}

variable "local_images_folder" {
  description = "Local folder name of the images"
  type        = string
  default     = "images"
}

variable "environment" {
  description = "Current environment of the deployment (e.g., Dev, Staging, Prod)"
  type        = string
  default     = "Dev"
}

variable "project_name" {
  description = "The name of the project used for resource identification and tagging"
  type        = string
  default     = "movies-app"
}

variable "availability_zone" {
  description = "The availability zone for the subnets"
  type        = string
  default     = "ap-south-1a"
}

variable "my_ip" {
  description = "My Ip address"
  type        = string
  default     = "103.86.181.75/32"
}

# variable "mysql_db_creds" {
#   description = "It contains the mysql db secret key and value pair"
#   default = {
#     (local.mysql_root_secret_key) = "password"
#     (local.mysql_user_secret_key) = "password"
#   }
#   sensitive = true

#   type = map(string)
# }

variable "database_name" {
  description = "The database name"
  type        = string
  default     = "movies_db"
}

variable "mysql_root_user_password" {
  description = "The password for root user."
  type        = string
  sensitive   = true
}

variable "mysql_abhay_user_password" {
  description = "The password for abhay user."
  type        = string
  sensitive   = true
}
