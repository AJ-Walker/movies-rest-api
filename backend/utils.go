package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func response(statusCode int, status bool, message string, data any) gin.H {
	return gin.H{"status": status, "statusCode": statusCode, "message": message, "data": data}
}

func generateUUID() (string, error) {
	id, err := uuid.NewV7()
	if err != nil {
		log.Printf("Error generating uuid: %v", err)
		return "", err
	}

	return id.String(), err
}
