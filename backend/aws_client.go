package main

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/bedrockruntime"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

var (
	BedrockClient       *bedrockruntime.Client
	S3Client            *s3.Client
	SecretManagerClient *secretsmanager.Client
)

func InitAWSClients() {
	log.Println("Initializing AWS SDK clients")

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(AWS_REGION))
	if err != nil {
		log.Fatalf("Unable to load AWS SDK config: %v", err)
	}

	BedrockClient = bedrockruntime.NewFromConfig(cfg)
	S3Client = s3.NewFromConfig(cfg)
	SecretManagerClient = secretsmanager.NewFromConfig(cfg)
}
