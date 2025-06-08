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

// Random provider
resource "random_id" "random_id" {
  byte_length = 4
}

// Locals
locals {
  files = fileset("${path.module}/${var.local_images_folder}", "*")

  mysql_root_user_secret_key = "mysql-root-user-password"
  mysql_user_secret_key = "mysql-abhay-user-password"
}

// VPC
resource "aws_vpc" "movies_app_vpc" {
  cidr_block = "10.2.0.0/20"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

// Public subnet 1a
resource "aws_subnet" "movies_app_public_subnet_1a" {
  vpc_id     = aws_vpc.movies_app_vpc.id
  cidr_block = "10.2.0.0/24"

  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-public-subnet-1a"
  }
}

// Private subnet 1a
resource "aws_subnet" "movies_app_private_subnet_1a" {
  vpc_id     = aws_vpc.movies_app_vpc.id
  cidr_block = "10.2.7.0/24"

  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-private-subnet-1a"
  }
}

// Internet gateway
resource "aws_internet_gateway" "movies_app_igw" {
  vpc_id = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

// Route tables
// Default main route table
resource "aws_default_route_table" "movies_app_main_rtb" {
  default_route_table_id = aws_vpc.movies_app_vpc.default_route_table_id

  tags = {
    Name = "${var.project_name}-main-rtb"
  }
}

// Public route table
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

// Public route table - public subnet association
resource "aws_route_table_association" "public_rtb_subnet_association" {
  subnet_id      = aws_subnet.movies_app_public_subnet_1a.id
  route_table_id = aws_route_table.movies_app_public_rtb.id
}

// Private route table
resource "aws_route_table" "movies_app_private_rtb" {
  vpc_id = aws_vpc.movies_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-private-rtb"
  }
}

// Private route table - private subnet association
resource "aws_route_table_association" "private_rtb_subnet_association" {
  subnet_id      = aws_subnet.movies_app_private_subnet_1a.id
  route_table_id = aws_route_table.movies_app_private_rtb.id
}

// Nat Gateway
resource "aws_nat_gateway" "nat_gateway" {
  subnet_id = aws_subnet.movies_app_public_subnet_1a.id
  allocation_id = aws_eip.elastic_ip.allocation_id

  depends_on = [ aws_internet_gateway.movies_app_igw ]

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

# Elastic IP
resource "aws_eip" "elastic_ip" {
  
  depends_on = [ aws_internet_gateway.movies_app_igw ]

  tags = {
    Name = "${var.project_name}-elastic-ip"
  }
}

// EC2 - MySQL DB Instance
resource "aws_instance" "mysql_db_ec2" {
  ami           = "ami-0e35ddab05955cf57" // Ubuntu Server 24.04 LTS (HVM)
  instance_type = "t2.micro"

  associate_public_ip_address = true
  availability_zone           = var.availability_zone

  subnet_id = aws_subnet.movies_app_public_subnet_1a.id

  key_name = aws_key_pair.movies_app_kp.key_name

  vpc_security_group_ids = [aws_security_group.ec2_ssh_allow_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "${var.project_name}-instance"
  }

  // mysql setup user-data
  user_data = templatefile("${path.module}/mysql_setup.tftpl", {
    mysql_db_secret_arn   = aws_secretsmanager_secret.mysql_db_secrets.arn,
    aws_region            = var.aws_region,
    mysql_db_name         = var.database_name,
    mysql_db_user         = "abhay"
    sql_script            = file("${path.module}/scripts.sql"),
    mysql_root_secret_key = local.mysql_root_user_secret_key,
    mysql_user_secret_key = local.mysql_user_secret_key
  })

  user_data_replace_on_change = true
}

// IAM EC2 role
resource "aws_iam_role" "movies_app_ec2_role" {
  name               = "movies-app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy_doc.json

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

resource "aws_iam_policy" "movies_app_ec2_policy" {
  name        = "movie-app-ec2-policy"
  description = "This policy has all the actions for ec2"
  policy      = data.aws_iam_policy_document.ec2_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "movies_app_ec2_policy_attach" {
  role       = aws_iam_role.movies_app_ec2_role.id
  policy_arn = aws_iam_policy.movies_app_ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.movies_app_ec2_role.name
}

// EC2 - Key pair
resource "aws_key_pair" "movies_app_kp" {
  key_name   = "terraform-ec2-kp"
  public_key = file("~/.ssh/terraform-ec2-kp.pub")

  tags = {
    Name = "${var.project_name}-kp"
  }
}

// Security Groups
// Allow SSH SG
resource "aws_security_group" "ec2_ssh_allow_sg" {
  name        = "ec2-ssh-allow-sg"
  description = "Allows SSH from my IP"
  vpc_id      = aws_vpc.movies_app_vpc.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_inbound" {
  security_group_id = aws_security_group.ec2_ssh_allow_sg.id
  description       = aws_security_group.ec2_ssh_allow_sg.description
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip
}

// Allow all outbound sg rule
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.ec2_ssh_allow_sg.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

// S3
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


// Secret Manager
resource "aws_secretsmanager_secret" "mysql_db_secrets" {
  name        = "movies-app-mysql-db-credentials-${random_id.random_id.hex}"
  description = "This secret is used to store the mysql user credentials"
}

resource "aws_secretsmanager_secret_version" "mysql_db_creds" {
  secret_id = aws_secretsmanager_secret.mysql_db_secrets.id
  secret_string = jsonencode({
    (local.mysql_root_user_secret_key) = var.mysql_root_user_password,
    (local.mysql_user_secret_key) = var.mysql_abhay_user_password
  })
}
