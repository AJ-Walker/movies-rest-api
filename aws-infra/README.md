# Movies REST API - AWS Infrastructure

This directory contains Terraform configuration files to deploy the complete AWS infrastructure for the Movies REST API application. The infrastructure sets up a scalable, secure three-tier architecture on AWS.

## Architecture Overview

The infrastructure provisions the following AWS resources:

- **VPC** with public and private subnets across multiple availability zones
- **Application Load Balancer (ALB)** for traffic distribution
- **EC2 instances** for MySQL database and Go backend application
- **S3 bucket** for storing movie cover images
- **AWS Secrets Manager** for secure credential storage
- **IAM roles and policies** for secure service communication
- **Security groups** with least-privilege access rules

## Project Structure

```
aws-infra/
├── main.tf              # Main infrastructure resources
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── data.tf              # Data sources and IAM policies
├── terraform.tf         # Terraform provider configuration
├── go_backend_setup.tftpl    # Go application deployment script
├── mysql_setup.tftpl         # MySQL database setup script
├── scripts.sql               # Database initialization scripts
└── images/                   # Movie cover images to upload to S3
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** installed (version 1.0 or higher)
4. Valid AWS account with necessary permissions

## Required Variables

Before deployment, you must provide the following variables:

### Required Variables (no defaults)
- `my_ip` - Your public IP address for secure access
- `mysql_root_user_password` - MySQL root user password (sensitive)
- `mysql_abhay_user_password` - MySQL application user password (sensitive)

### Optional Variables (have defaults)
- `aws_region` - AWS region (default: "ap-south-1")
- `environment` - Deployment environment (default: "Dev")
- `project_name` - Project name for resource naming (default: "movies-app")
- `bucket_name` - S3 bucket name (default: "movies-app-data")
- `database_name` - MySQL database name (default: "movies_db")
- `database_user` - MySQL application user (default: "abhay")
- `repo_url` - GitHub repository URL (default: "https://github.com/AJ-Walker/movies-rest-api")

## Deployment Instructions

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Create terraform.tfvars file
Create a `terraform.tfvars` file with your specific values:

```hcl
my_ip = "your.public.ip.address/32"
mysql_root_user_password = "your-secure-root-password"
mysql_abhay_user_password = "your-secure-user-password"
```

### 3. Plan the deployment
```bash
terraform plan
```

### 4. Apply the configuration
```bash
terraform apply
```

### 5. Confirm deployment
Type `yes` when prompted to confirm the deployment.

## Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/20 CIDR block with DNS hostnames enabled
- **Public Subnets**: For ALB in multiple AZs (10.0.1.0/24, 10.0.2.0/24)
- **Private Subnet**: For backend and database instances (10.0.11.0/24)
- **Internet Gateway**: For public internet access
- **NAT Gateway**: For outbound internet access from private subnet

### Compute
- **MySQL EC2 Instance**: Ubuntu 24.04 LTS, t2.micro in private subnet
- **Go Backend EC2 Instance**: Ubuntu 24.04 LTS, t2.micro in private subnet
- **Application Load Balancer**: Internet-facing ALB with health checks

### Storage & Security
- **S3 Bucket**: Stores movie cover images with public read access
- **Secrets Manager**: Securely stores MySQL credentials
- **Security Groups**: Restrict traffic between components
- **IAM Roles**: Least-privilege access for EC2 instances

## Security Features

### Network Security
- Private subnets isolate backend components from direct internet access
- Security groups implement least-privilege access rules
- NACLs provide additional network-level security

### Application Security
- MySQL credentials stored in AWS Secrets Manager
- IAM roles with minimal required permissions
- No hardcoded secrets in configuration files

### Access Control
- Database accessible only from backend instances
- Backend accessible only through load balancer
- Public access limited to ALB endpoints

## Application Deployment

The infrastructure automatically:

1. **MySQL Setup**:
   - Installs and configures MySQL server
   - Creates database and application user
   - Executes initialization scripts
   - Configures remote access from backend

2. **Go Backend Setup**:
   - Installs Go 1.24.4
   - Clones and builds the application
   - Configures systemd service
   - Sets up Nginx as reverse proxy
   - Configures environment variables

## Outputs

After successful deployment, Terraform outputs:

- `vpc_id` - VPC identifier
- `mysql_ec2_private_dns` - MySQL database connection endpoint
- `secret_manager_arn` - ARN for database credentials
- `alb_dns_name` - Public load balancer endpoint for API access

## API Access

Once deployed, access the Movies REST API at:
```
http://<alb_dns_name>/
```

Available endpoints include:
- `GET /healthcheck` - Health check endpoint
- `GET /movies` - List all movies
- `POST /movies` - Create new movie
- `GET /movies/{id}` - Get specific movie
- `PUT /movies/{id}` - Update movie
- `DELETE /movies/{id}` - Delete movie

## Monitoring and Troubleshooting

### Check Application Status
```bash
# Connect to backend instance via Session Manager
aws ssm start-session --target <backend-instance-id>

# Check Go application status
sudo systemctl status movies-app.service

# View application logs
sudo journalctl -u movies-app.service -f

# Check Nginx status
sudo systemctl status nginx
```

### Check Database Status
```bash
# Connect to database instance via Session Manager
aws ssm start-session --target <mysql-instance-id>

# Check MySQL status
sudo systemctl status mysql

# Connect to MySQL (credentials in Secrets Manager)
mysql -u abhay -p movies_db
```

## Cleanup

To destroy all infrastructure resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources including the database and uploaded images.

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check AWS credentials and permissions
2. **Application Not Accessible**: Verify security group rules and ALB configuration
3. **Database Connection Issues**: Check MySQL configuration and secrets
4. **Build Failures**: Review user data scripts in CloudWatch logs

### Logs Location
- EC2 instance logs: `/var/log/cloud-init-output.log`
- Application logs: `sudo journalctl -u movies-app.service`
- Nginx logs: `/var/log/nginx/movies-app-error.log`

## Contributing

When modifying the infrastructure:

1. Update variable descriptions and defaults as needed
2. Test changes in a development environment first
3. Update this README with any new components or procedures
4. Follow Terraform best practices for resource naming and tagging

## Support

For issues related to:
- Infrastructure: Check Terraform documentation and AWS service limits
- Application: Refer to the main repository at https://github.com/AJ-Walker/movies-rest-api
- Database: Review MySQL configuration and connection settings
