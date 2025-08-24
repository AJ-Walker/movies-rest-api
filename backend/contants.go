package main

// AWS configuration constants used throughout the application
const (
	// AWS_REGION specifies the geographic region for AWS services (Mumbai)
	AWS_REGION string = "ap-south-1"

	// MODEL_ID defines the AWS Bedrock AI model identifier for Claude 3 Sonnet
	MODEL_ID string = "anthropic.claude-3-sonnet-20240229-v1:0"

	// BUCKET_NAME is the S3 bucket used for storing application data
	BUCKET_NAME string = "movies-app-data"
)
