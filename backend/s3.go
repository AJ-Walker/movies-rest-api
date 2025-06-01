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

const s3Prefix = "images"

func PutObject_S3(fileHeader *multipart.FileHeader, objectKey string) (string, error) {
	log.Print("Inside PutObject_S3 func")
	file, err := fileHeader.Open()

	defer file.Close()

	if err != nil {
		log.Printf("Error opening file to upload: %v", err)
		return "", err
	}

	key := fmt.Sprintf("%v/%v", s3Prefix, objectKey)

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

	if err := s3.NewObjectExistsWaiter(S3Client).Wait(context.TODO(), &s3.HeadObjectInput{
		Bucket: aws.String(BUCKET_NAME),
		Key:    aws.String(key),
	}, time.Minute); err != nil {
		log.Printf("Error waiting file: %v", err)
		return "", err
	}

	objectUrl := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", BUCKET_NAME, AWS_REGION, key)

	return objectUrl, nil
}

func DeleteObject_S3(objectKey string) error {
	log.Print("Inside DeleteObject_S3 func")

	key := fmt.Sprintf("%v/%v", s3Prefix, objectKey)
	log.Printf("key: %v", key)

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
