# Movies REST API

A full-stack cloud-native movies management system built with Go and deployed on AWS infrastructure using Terraform. This project demonstrates modern DevOps practices, cloud architecture, and AI integration.

## Project Overview

This application provides a complete REST API for managing movie collections with the following features:

- **CRUD Operations**: Create, read, update, and delete movies
- **Image Management**: Upload and store movie cover images in AWS S3
- **AI Integration**: Generate movie summaries using AWS Bedrock (Claude 3 Sonnet)
- **Secure Storage**: Database credentials managed via AWS Secrets Manager
- **Cloud Infrastructure**: Fully automated AWS deployment using Terraform
- **Scalable Architecture**: Load balancer, private subnets, and auto-scaling ready design

## Architecture

### Backend Components
- **Go REST API**: High-performance Gin framework with middleware
- **MySQL Database**: Relational database for movie metadata
- **AWS S3**: Object storage for movie cover images
- **AWS Bedrock**: AI service for intelligent content generation
- **AWS Secrets Manager**: Secure credential management

### Infrastructure Components  
- **VPC**: Isolated network environment with public/private subnets
- **Application Load Balancer**: Traffic distribution and health checking
- **EC2 Instances**: Compute resources for database and application
- **Security Groups**: Network-level security with least privilege access
- **IAM Roles**: Fine-grained AWS service permissions

## Project Structure

```
movies-rest-api/
├── README.md                 # This file - main project documentation
├── backend/                  # Go REST API application
│   ├── main.go              # Application entry point and HTTP routes
│   ├── database.go          # MySQL operations and connection management
│   ├── aws_client.go        # AWS service client initialization
│   ├── s3.go                # S3 operations for image management
│   ├── bedrock.go           # AI integration for summary generation
│   ├── secret_manager.go    # Secure credential retrieval
│   ├── utils.go             # Helper functions and utilities
│   ├── contants.go          # Application configuration constants
│   ├── go.mod               # Go module dependencies
│   ├── scripts.sql          # Database schema and sample data
│   └── README.md            # Backend-specific documentation
├── aws-infra/               # Terraform infrastructure as code
│   ├── main.tf              # Core AWS resources definition
│   ├── variables.tf         # Input variables and configuration
│   ├── outputs.tf           # Infrastructure outputs and endpoints
│   ├── data.tf              # Data sources and IAM policies
│   ├── terraform.tf         # Provider configuration
│   ├── go_backend_setup.tftpl    # Application deployment script
│   ├── mysql_setup.tftpl         # Database installation and setup
│   ├── scripts.sql               # Database initialization
│   ├── images/                   # Sample movie cover images
│   └── README.md                 # Infrastructure documentation
```

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Go >= 1.24 (for local development)
- kubectl in PATH (as per configuration)

### 1. Deploy Infrastructure

```bash
cd aws-infra

# Initialize Terraform
terraform init

# Create terraform.tfvars with your values
echo 'my_ip = "your.public.ip.address/32"' > terraform.tfvars
echo 'mysql_root_user_password = "your-secure-root-password"' >> terraform.tfvars
echo 'mysql_abhay_user_password = "your-secure-user-password"' >> terraform.tfvars

# Deploy infrastructure
terraform plan
terraform apply
```

### 2. Access the API

Once deployed, Terraform will output the Application Load Balancer DNS name:

```bash
# Get the API endpoint
terraform output alb_dns_name

# Test the health endpoint
curl http://<alb_dns_name>/healthcheck
```

## API Endpoints

### Base URL
```
http://<alb_dns_name>
```

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/healthcheck` | Health status check |
| GET | `/api/movies` | List all movies (optional `?year` filter) |
| GET | `/api/movies/{id}` | Get specific movie by ID |
| POST | `/api/movies` | Create new movie (with file upload) |
| PUT | `/api/movies/{id}` | Update existing movie |
| DELETE | `/api/movies/{id}` | Delete movie and associated image |
| GET | `/api/movies/{id}/summary` | Get AI-generated movie summary |

### Example API Usage

```bash
# List all movies
curl -X GET http://<alb_dns_name>/api/movies

# Filter movies by year
curl -X GET "http://<alb_dns_name>/api/movies?year=2023"

# Get specific movie
curl -X GET http://<alb_dns_name>/api/movies/1

# Create new movie with cover image
curl -X POST http://<alb_dns_name>/api/movies \
  -F "title=Inception" \
  -F "releaseYear=2010" \
  -F "genre=Sci-Fi" \
  -F "coverImage=@/path/to/image.jpg"

# Get AI-generated summary
curl -X GET http://<alb_dns_name>/api/movies/1/summary
```

### Response Format
All API responses follow a consistent format:

```json
{
  "status": true,
  "statusCode": 200,
  "message": "Movies fetched successfully.",
  "data": [
    {
      "movieId": 1,
      "title": "The Shawshank Redemption",
      "releaseYear": 1994,
      "genre": "Drama",
      "coverUrl": "https://s3.amazonaws.com/movies-app-data/images/uuid.jpg",
      "generatedSummary": "AI-generated summary..."
    }
  ]
}
```

## Cloud Architecture

### Network Design
- **VPC**: 10.0.0.0/20 with DNS resolution enabled
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (Multi-AZ for ALB)
- **Private Subnet**: 10.0.11.0/24 (Database and application instances)
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Secure outbound internet for private instances

### Security Features
- **Security Groups**: Least-privilege network access rules
- **IAM Roles**: Fine-grained AWS service permissions
- **Secrets Manager**: Encrypted credential storage
- **Private Subnets**: Database and application isolation
- **Load Balancer**: SSL termination and health checking

## AI Integration

The application integrates with **AWS Bedrock** using **Claude 3 Sonnet** to generate intelligent movie summaries:

- **Model**: `anthropic.claude-3-sonnet-20240229-v1:0`
- **Summary Length**: 100 words maximum
- **Caching**: Generated summaries are stored in the database
- **Context-aware**: Uses movie title, year, and genre for better accuracy

## 🔧 Local Development

### Backend Development

```bash
cd backend

# Install dependencies
go mod tidy

# Create .env file with local configuration
cat > .env << EOF
DB_USER=your_db_user
DB_NAME=movies_db
DB_SECRET_KEY=mysql-user-password
SECRET_ARN=your-secret-arn
HOST=localhost
PORT=3306
EOF

# Run locally
go run .

# Or use hot reload with Air
air
```

### Database Setup (Local)

```bash
# Install MySQL locally
sudo apt install mysql-server

# Create database and user
mysql -u root -p
CREATE DATABASE movies_db;
CREATE USER 'your_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON movies_db.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;

# Import schema
mysql -u your_user -p movies_db < backend/scripts.sql
```

## Monitoring & Troubleshooting

### Infrastructure Monitoring

```bash
# Check instance status
aws ssm start-session --target <instance-id>

# View application logs
sudo journalctl -u movies-app.service -f

# Check nginx status
sudo systemctl status nginx

# Database connection test
mysql -u abhay -p movies_db
```

### Common Issues

1. **API Not Responding**: Check ALB health checks and security groups
2. **Database Connection Errors**: Verify Secrets Manager configuration
3. **Image Upload Failures**: Check S3 bucket permissions and IAM roles
4. **AI Summary Errors**: Verify Bedrock service availability in region

### Log Locations
- **Application**: `sudo journalctl -u movies-app.service`
- **Nginx**: `/var/log/nginx/movies-app-error.log`
- **System**: `/var/log/cloud-init-output.log`

## Testing

The infrastructure includes 20 sample movies with cover images for testing:

- Popular movies from various genres
- Pre-configured S3 URLs for images
- Sample data automatically loaded during deployment

## Scaling Considerations

### Current Architecture
- Single EC2 instance for backend (can be converted to Auto Scaling Group)
- Single MySQL instance (can be migrated to RDS with Multi-AZ)
- ALB ready for multiple backend instances

## Security Best Practices

- Credentials stored in Secrets Manager
- Private subnets for backend components
- Least-privilege IAM policies
- Security groups with specific port access
- No hardcoded secrets in code

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Go best practices and conventions
- Update documentation for new features
- Test infrastructure changes in development environment
- Maintain backward compatibility for API changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:

- **Infrastructure Issues**: Check AWS documentation and Terraform guides
- **Application Issues**: Review Go application logs and error messages
- **API Usage**: Refer to the endpoint documentation above
- **AWS Costs**: Monitor usage through AWS Cost Explorer

## Related Links

- [Go Gin Framework Documentation](https://gin-gonic.com/en/docs/)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
