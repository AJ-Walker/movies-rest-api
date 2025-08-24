package main

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/bedrockruntime"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// AWS service clients used across the application.
var (
	// BedrockClient is the client for interacting with Amazon Bedrock.
	BedrockClient *bedrockruntime.Client

	// S3Client is the client for performing operations on Amazon S3.
	S3Client *s3.Client

	// SecretManagerClient is the client for retrieving and managing secrets in AWS Secrets Manager.
	SecretManagerClient *secretsmanager.Client
)

// InitAWSClients initializes AWS service clients for Bedrock, S3, and Secrets Manager.
// It loads the default AWS configuration (including credentials and region) and
// creates clients that can be reused throughout the application.
func InitAWSClients() {
	log.Println("Initializing AWS SDK clients")

	// Load the AWS configuration with the application’s specified region.
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(AWS_REGION))
	if err != nil {
		log.Fatalf("Unable to load AWS SDK config: %v", err)
	}

	// Initialize clients for AWS services using the shared configuration.
	BedrockClient = bedrockruntime.NewFromConfig(cfg)
	S3Client = s3.NewFromConfig(cfg)
	SecretManagerClient = secretsmanager.NewFromConfig(cfg)
}
