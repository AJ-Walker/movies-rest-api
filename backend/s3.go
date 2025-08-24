package main

import (
	"context"
	"fmt"
	"log"
	"mime/multipart"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// s3Prefix defines the folder structure for storing images in the S3 bucket
const s3Prefix = "images"

// PutObject_S3 uploads a file to Amazon S3 and returns its public URL
func PutObject_S3(fileHeader *multipart.FileHeader, objectKey string) (string, error) {
	log.Print("Inside PutObject_S3 func")

	// Open the file from the multipart form data
	file, err := fileHeader.Open()
	if err != nil {
		log.Printf("Error opening file to upload: %v", err)
		return "", err
	}

	defer file.Close()

	// Construct the complete S3 key with prefix
	key := fmt.Sprintf("%v/%v", s3Prefix, objectKey)

	// Upload the file to S3 with content type preservation
	_, err = S3Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(BUCKET_NAME),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(fileHeader.Header.Get("Content-Type")),
	})

	if err != nil {
		log.Printf("Error uploading file: %v", err)
		return "", err
	}

	// Wait for the object to be available in S3
	if err := s3.NewObjectExistsWaiter(S3Client).Wait(context.TODO(), &s3.HeadObjectInput{
		Bucket: aws.String(BUCKET_NAME),
		Key:    aws.String(key),
	}, time.Minute); err != nil {
		log.Printf("Error waiting file: %v", err)
		return "", err
	}

	// Generate the public URL for the uploaded file
	objectUrl := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", BUCKET_NAME, AWS_REGION, key)

	return objectUrl, nil
}

// DeleteObject_S3 removes a file from Amazon S3
func DeleteObject_S3(objectKey string) error {
	log.Print("Inside DeleteObject_S3 func")

	// Construct the complete S3 key with prefix
	key := fmt.Sprintf("%v/%v", s3Prefix, objectKey)
	log.Printf("key: %v", key)

	// Delete the object from S3
	_, err := S3Client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(BUCKET_NAME),
		Key:    aws.String(key),
	})

	if err != nil {
		log.Print(err)
		return err
	}
	return nil
}
