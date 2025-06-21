provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# Random provider
resource "random_id" "random_id" {
  byte_length = 4
}

# Locals
locals {
  files = fileset("${path.module}/${var.local_images_folder}", "*")

  mysql_root_user_secret_key = "mysql-root-user-password"
  mysql_user_secret_key      = "mysql-abhay-user-password"
}

# VPC
resource "aws_vpc" "movies_app_vpc" {
  cidr_block = "10.2.0.0/20"

  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public subnet 1a
resource "aws_subnet" "movies_app_public_subnet_1a" {
  vpc_id     = aws_vpc.movies_app_vpc.id
  cidr_block = "10.2.0.0/24"

  availability_zone = var.availability_zone_1a

  tags = {
    Name = "${var.project_name}-public-subnet-1a"
  }
}

# Public subnet 1b
resource "aws_subnet" "movies_app_public_subnet_1b" {
  vpc_id     = aws_vpc.movies_app_vpc.id
  cidr_block = "10.2.1.0/24"

  availability_zone = var.availability_zone_1b

  tags = {
    Name = "${var.project_name}-public-subnet-1b"
  }
}

# Private subnet 1a
resource "aws_subnet" "movies_app_private_subnet_1a" {
  vpc_id     = aws_vpc.movies_app_vpc.id
  cidr_block = "10.2.7.0/24"

  availability_zone = var.availability_zone_1a

  tags = {
    Name = "${var.project_name}-private-subnet-1a"
  }
}

# Internet gateway
resource "aws_internet_gateway" "movies_app_igw" {
  vpc_id = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route tables
# Default main route table
resource "aws_default_route_table" "movies_app_main_rtb" {
  default_route_table_id = aws_vpc.movies_app_vpc.default_route_table_id

  tags = {
    Name = "${var.project_name}-main-rtb"
  }
}

# Public route table
resource "aws_route_table" "movies_app_public_rtb" {
  vpc_id = aws_vpc.movies_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.movies_app_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rtb"
  }
}

# Public route table - public subnet association
resource "aws_route_table_association" "public_rtb_subnet_association" {
  subnet_id      = aws_subnet.movies_app_public_subnet_1a.id
  route_table_id = aws_route_table.movies_app_public_rtb.id
}

# Private route table
resource "aws_route_table" "movies_app_private_rtb" {
  vpc_id = aws_vpc.movies_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-private-rtb"
  }
}

# Private route table - private subnet association
resource "aws_route_table_association" "private_rtb_subnet_association" {
  subnet_id      = aws_subnet.movies_app_private_subnet_1a.id
  route_table_id = aws_route_table.movies_app_private_rtb.id
}

# Nat Gateway
resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.movies_app_public_subnet_1a.id
  allocation_id = aws_eip.elastic_ip.allocation_id

  depends_on = [aws_internet_gateway.movies_app_igw]

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

# Elastic IP
resource "aws_eip" "elastic_ip" {

  depends_on = [aws_internet_gateway.movies_app_igw]

  tags = {
    Name = "${var.project_name}-elastic-ip"
  }
}

# MySQL Database
# EC2 Instance
resource "aws_instance" "mysql_db_ec2" {
  ami           = "ami-0e35ddab05955cf57" # Ubuntu Server 24.04 LTS (HVM)
  instance_type = "t2.micro"

  availability_zone = var.availability_zone_1a
  subnet_id         = aws_subnet.movies_app_private_subnet_1a.id

  vpc_security_group_ids = [aws_security_group.mysql_db_sg.id]

  iam_instance_profile = aws_iam_instance_profile.mysql_db_instance_profile.name

  tags = {
    Name = "${var.project_name}-mysql-db-instance"
  }

  # mysql setup user-data
  user_data = templatefile("${path.module}/mysql_setup.tftpl", {
    mysql_db_secret_arn   = aws_secretsmanager_secret.mysql_db_secrets.arn,
    aws_region            = var.aws_region,
    mysql_db_name         = var.database_name,
    mysql_db_user         = var.database_user
    sql_script            = file("${path.module}/scripts.sql"),
    mysql_root_secret_key = local.mysql_root_user_secret_key,
    mysql_user_secret_key = local.mysql_user_secret_key
  })

  user_data_replace_on_change = true

  depends_on = [aws_nat_gateway.nat_gateway]
}

# Security Group - MySQL DB Instance SG
resource "aws_security_group" "mysql_db_sg" {
  name        = "${var.project_name}-mysql-db-sg"
  description = "Security group for MySQL DB EC2 instance"
  vpc_id      = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-mysql-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_from_backend" {
  security_group_id            = aws_security_group.mysql_db_sg.id
  description                  = "Allow MySQL (port 3306) access from backend EC2"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.backend_ec2_sg.id # Backend EC2 SG Id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_from_db" {
  security_group_id = aws_security_group.mysql_db_sg.id
  description       = "Allow all outbound traffic from MySQL EC2 instance"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# IAM Role - Mysql DB Instance IAM Role
resource "aws_iam_instance_profile" "mysql_db_instance_profile" {
  name = "${var.project_name}-mysql-db-instance-profile"
  role = aws_iam_role.mysql_db_ec2_role.name
}

resource "aws_iam_role" "mysql_db_ec2_role" {
  name               = "movies-app-mysql-db-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy_doc.json

  tags = {
    Name = "${var.project_name}-mysql-db-ec2-role"
  }
}

resource "aws_iam_policy" "mysql_ec2_secrets_policy" {
  name        = "${var.project_name}-mysql-ec2-secrets-policy"
  description = "Allows MySQL EC2 instance to retrieve DB credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.mysql_ec2_secrets_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "mysql_db_ec2_role_attach_ssm_access" {
  role       = aws_iam_role.mysql_db_ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "mysql_ec2_secrets_policy_attach" {
  role       = aws_iam_role.mysql_db_ec2_role.id
  policy_arn = aws_iam_policy.mysql_ec2_secrets_policy.arn
}


# GO Backend
# EC2 Instance
resource "aws_instance" "go_backend_ec2" {
  ami           = "ami-0e35ddab05955cf57" # Ubuntu Server 24.04 LTS (HVM)
  instance_type = "t2.micro"

  availability_zone = var.availability_zone_1a
  subnet_id         = aws_subnet.movies_app_private_subnet_1a.id

  vpc_security_group_ids = [aws_security_group.backend_ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.backend_instance_profile.name

  tags = {
    Name = "${var.project_name}-backend-instance"
  }

  # go backend setup user-data
  user_data = templatefile("${path.module}/go_backend_setup.tftpl", {
    app_name              = var.project_name,
    repo_url              = var.repo_url,
    repo_name             = var.repo_name,
    mysql_db_name         = var.database_name,
    mysql_db_user         = var.database_user,
    mysql_user_secret_key = local.mysql_user_secret_key,
    mysql_db_secret_arn   = aws_secretsmanager_secret.mysql_db_secrets.arn,
    mysql_db_host         = aws_instance.mysql_db_ec2.private_dns,
    mysql_db_port         = "3306"
  })

  user_data_replace_on_change = true

  depends_on = [aws_nat_gateway.nat_gateway]
}

# Security Group - Go Backend EC2 Instance
resource "aws_security_group" "backend_ec2_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Security group for backend EC2 instance"
  vpc_id      = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_alb" {
  security_group_id            = aws_security_group.backend_ec2_sg.id
  description                  = "Allow HTTP (port 80) traffic from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.movies_app_alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_from_backend" {
  security_group_id = aws_security_group.backend_ec2_sg.id
  description       = "Allow all outbound traffic from backend EC2"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# IAM Role - Backend Instance IAM Role
resource "aws_iam_instance_profile" "backend_instance_profile" {
  name = "${var.project_name}-backend-instance-profile"
  role = aws_iam_role.backend_ec2_role.name
}

resource "aws_iam_role" "backend_ec2_role" {
  name               = "movies-app-backend-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy_doc.json

  tags = {
    Name = "${var.project_name}-backend-ec2-role"
  }
}

resource "aws_iam_policy" "backend_ec2_policy" {
  name        = "${var.project_name}-backend-ec2-policy"
  description = "Policy for backend EC2 instance to access Secrets Manager, S3, and Bedrock"
  policy      = data.aws_iam_policy_document.backend_ec2_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "backend_ec2_role_attach_ssm_access" {
  role       = aws_iam_role.backend_ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "backend_ec2_policy_attach" {
  role       = aws_iam_role.backend_ec2_role.id
  policy_arn = aws_iam_policy.backend_ec2_policy.arn
}

# S3
resource "aws_s3_bucket" "movies_app_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "aws_s3_object" "movies_app_cover_images" {
  for_each     = local.files
  bucket       = aws_s3_bucket.movies_app_bucket.id
  key          = "${var.s3_images_prefix}/${each.value}"
  source       = "${path.module}/${var.local_images_folder}/${each.value}"
  etag         = filemd5("${path.module}/${var.local_images_folder}/${each.value}")
  content_type = "application/octet-stream"
}

resource "aws_s3_bucket_public_access_block" "movies_app_bucket_public_access" {
  bucket = aws_s3_bucket.movies_app_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_policy" "allow_get_images_policy" {
  bucket = aws_s3_bucket.movies_app_bucket.id
  policy = data.aws_iam_policy_document.allow_get_s3_images_policy.json

  depends_on = [aws_s3_bucket_public_access_block.movies_app_bucket_public_access]
}


# Secret Manager
resource "aws_secretsmanager_secret" "mysql_db_secrets" {
  name        = "movies-app-mysql-db-credentials-${random_id.random_id.hex}"
  description = "This secret is used to store the mysql user credentials"
}

resource "aws_secretsmanager_secret_version" "mysql_db_creds" {
  secret_id = aws_secretsmanager_secret.mysql_db_secrets.id
  secret_string = jsonencode({
    (local.mysql_root_user_secret_key) = var.mysql_root_user_password,
    (local.mysql_user_secret_key)      = var.mysql_abhay_user_password
  })
}


# Load Balancer
# Target Group
resource "aws_lb_target_group" "movies_app_backend_tg" {
  name        = "movies-app-backend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.movies_app_vpc.id

  health_check {
    path = "/healthcheck"
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# TG attach ec2 instance
resource "aws_lb_target_group_attachment" "backend_tg_attach_ec2" {
  target_group_arn = aws_lb_target_group.movies_app_backend_tg.arn
  target_id        = aws_instance.go_backend_ec2.id
  port             = 80
}

# ALB
resource "aws_lb" "movies_app_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false

  subnets = [aws_subnet.movies_app_public_subnet_1a.id, aws_subnet.movies_app_public_subnet_1b.id]

  security_groups = [aws_security_group.movies_app_alb_sg.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ALB 80 listener rule
resource "aws_lb_listener" "alb_80_listener_rule" {
  load_balancer_arn = aws_lb.movies_app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.movies_app_backend_tg.arn
  }

  tags = {
    Name = "alb-listener-80"
  }
}

# Security Group - ALB
resource "aws_security_group" "movies_app_alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application load balancer"
  vpc_id      = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_internet" {
  security_group_id = aws_security_group.movies_app_alb_sg.id
  description       = "Allow HTTP (port 80) traffic from the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_from_alb" {
  security_group_id = aws_security_group.movies_app_alb_sg.id
  description       = "Allow all outbound traffic from ALB"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
