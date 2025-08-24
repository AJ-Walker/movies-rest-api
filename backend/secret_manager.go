package main

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// GetSecretByKey retrieves a specific secret value from AWS Secrets Manager.
// It fetches the secret JSON object and extracts the value for the specified key
func GetSecretByKey(secretId string, secretKey string) (string, error) {
	// Retrieve the secret value from AWS Secrets Manager
	output, err := SecretManagerClient.GetSecretValue(context.TODO(), &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretId),
	})

	if err != nil {
		log.Printf("Error getting secrets: %v", err)
		return "", err
	}

	// Parse the JSON string into a map
	var secretString map[string]string
	err = json.Unmarshal([]byte(*output.SecretString), &secretString)
	if err != nil {
		return "", err
	}

	log.Print(secretString[secretKey])

	// Return the value for the specified key
	return secretString[secretKey], nil
}
