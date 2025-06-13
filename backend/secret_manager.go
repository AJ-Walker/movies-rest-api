package main

import (
	"context"
	"log"

	"encoding/json"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

func GetSecretByKey(secretId string, secretKey string) (string, error) {

	output, err := SecretManagerClient.GetSecretValue(context.TODO(), &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretId),
	})

	if err != nil {
		log.Printf("Error getting secrets: %v", err)
		return "", err
	}

	var secretString map[string]string

	err = json.Unmarshal([]byte(*output.SecretString), &secretString)
	if err != nil {
		return "", err
	}

	log.Print(secretString[secretKey])

	return secretString[secretKey], nil
}
