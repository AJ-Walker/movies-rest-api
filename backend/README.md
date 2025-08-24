# Movies REST API Backend

## Project Structure
```
backend/
├── .air.toml             # Air configuration for hot reload development
├── aws_client.go         # AWS service clients initialization
├── bedrock.go            # AWS Bedrock AI service integration
├── contants.go           # Application constants and configuration
├── database.go           # Database operations and MySQL connectivity
├── go.mod                # Go module dependencies
├── go.sum                # Go module checksums
├── main.go               # Main application entry point and HTTP routes
├── s3.go                 # AWS S3 storage operations
├── scripts.sql           # Database schema and sample data
├── secret_manager.go     # AWS Secrets Manager integration
└── utils.go              # Utility functions and helpers
```

## Core Components

### 1. **main.go** - Application Entry Point
- **Purpose**: Main server setup, route definitions, and HTTP handlers
- **Key Features**:
  - Gin framework setup with middleware
  - REST API route grouping (`/api/movies`)
  - Environment variables loading
  - AWS clients initialization
  - Database connection and health checks
  - Multipart form handling (10MB limit)

**API Endpoints**:
```
GET    /healthcheck          # Health status check
GET    /api/movies           # List all movies (optional ?year filter)
GET    /api/movies/:movieId  # Get specific movie by ID
POST   /api/movies           # Create new movie (with image upload)
PUT    /api/movies/:movieId  # Update existing movie
DELETE /api/movies/:movieId  # Delete movie and associated S3 image
GET    /api/movies/:movieId/summary # Get AI-generated summary
```

### 2. **database.go** - Data Layer
- **Purpose**: MySQL database operations and connection management
- **Key Functions**:
  - `DBConnectAndPing()` - Database connection setup
  - `GetAllMovies_DB()` - Fetch all movies
  - `GetMoviesByYear_DB()` - Filter movies by release year
  - `GetMovieById_DB()` - Get single movie by ID
  - `GetMovieSummary_DB()` - Get or generate movie summary
  - `AddMovie_DB()` - Insert new movie record
  - `UpdateMovieById_DB()` - Update existing movie
  - `DeleteMovieById_DB()` - Remove movie from database
  - `GetMovieByTitle_DB()` - Check for duplicate titles

### 3. **aws_client.go** - AWS Service Clients
- **Purpose**: Initialize AWS SDK clients for various services
- **Services**:
  - **BedrockClient**: AI/ML service for summary generation
  - **S3Client**: Object storage for movie cover images
  - **SecretManagerClient**: Secure credential management
- **Configuration**: Uses AWS region from constants (ap-south-1)

### 4. **s3.go** - Object Storage Operations
- **Purpose**: Handle file uploads and management in AWS S3
- **Key Functions**:
  - `PutObject_S3()` - Upload movie cover images
  - `DeleteObject_S3()` - Remove images when movies are deleted
- **Features**:
  - UUID-based unique file naming
  - Content-Type handling
  - Object existence verification
  - Structured S3 key naming (`images/{uuid}{extension}`)

### 5. **bedrock.go** - AI Integration
- **Purpose**: Generate movie summaries using AWS Bedrock
- **AI Model**: Claude 3 Sonnet (anthropic.claude-3-sonnet-20240229-v1:0)
- **Features**:
  - Contextual prompt generation based on movie data
  - 100-word summary limit
  - Conversation API with system prompts
  - Error handling and validation

### 6. **secret_manager.go** - Secure Credential Management
- **Purpose**: Retrieve sensitive data from AWS Secrets Manager
- **Function**: `GetSecretByKey()` - Extract specific secrets by key
- **Usage**: Database password retrieval for secure connections

### 7. **utils.go** - Helper Functions
- **Purpose**: Common utility functions
- **Functions**:
  - `response()` - Standardized API response format
  - `generateUUID()` - UUID v7 generation for file naming

### 8. **contants.go** - Configuration Constants
- **AWS_REGION**: "ap-south-1"
- **MODEL_ID**: "anthropic.claude-3-sonnet-20240229-v1:0"
- **BUCKET_NAME**: "movies-app-data"

## Data Model

### Movie Struct
```go
type Movie struct {
    MovieId          int     `json:"movieId"`
    Title            string  `json:"title"`
    ReleaseYear      uint16  `json:"releaseYear"`
    Genre            string  `json:"genre"`
    CoverUrl         *string `json:"coverUrl"`
    GeneratedSummary *string `json:"generatedSummary"`
}
```

### Database Schema (scripts.sql)
```sql
CREATE TABLE movie_details (
    movieId INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    releaseYear SMALLINT NOT NULL,
    genre VARCHAR(100) NOT NULL,
    coverUrl VARCHAR(255),
    generatedSummary TEXT
);
```

## Development Setup

### Dependencies (go.mod)
- **Web Framework**: `github.com/gin-gonic/gin v1.10.1`
- **Database**: `github.com/go-sql-driver/mysql v1.9.2`
- **AWS SDK**: `github.com/aws/aws-sdk-go-v2` (multiple services)
- **Utilities**: 
  - `github.com/google/uuid v1.6.0`
  - `github.com/joho/godotenv v1.5.1`

### Hot Reload (.air.toml)
- **Tool**: Air for automatic rebuilding during development
- **Build Target**: `./tmp/main`
- **Watch**: `.go`, `.tpl`, `.tmpl`, `.html` files
- **Excludes**: Test files, temp directories

## Security Features

1. **Credential Management**: AWS Secrets Manager integration
2. **Input Validation**: Form data validation and sanitization
3. **Duplicate Prevention**: Title uniqueness checks
4. **Error Handling**: Comprehensive error responses
5. **Resource Cleanup**: Automatic S3 cleanup on movie deletion

## Key Features

1. **RESTful Design**: Standard HTTP methods and status codes
2. **File Upload**: Multipart form handling for cover images
3. **AI Integration**: Smart summary generation with caching
4. **Cloud Native**: Full AWS service integration
5. **Scalable Architecture**: Microservice-ready design
6. **Development Friendly**: Hot reload and comprehensive logging

## API Response Format
```json
{
  "status": boolean,
  "statusCode": integer,
  "message": "string",
  "data": object|null
}
```

## Environment Variables Required
- `SECRET_ARN` - AWS Secrets Manager ARN
- `DB_SECRET_KEY` - Database password key in secrets
- `DB_USER` - Database username
- `HOST` - Database host
- `PORT` - Database port
- `DB_NAME` - Database name

## Sample Data
The `scripts.sql` includes 20 popular movies with pre-configured S3 image URLs for testing and development purposes.
