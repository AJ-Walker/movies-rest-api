package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/bedrockruntime"
	"github.com/aws/aws-sdk-go-v2/service/bedrockruntime/types"
)

// GenerateMovieSummary generates a short summary (approx. 100 words) for the given movie.
// It uses Amazon Bedrock's Converse API with a predefined model and returns the summary text.
func GenerateMovieSummary(movie Movie) (string, error) {
	log.Print("Inside GenerateMovieSummary func")

	// Configure inference settings (e.g., maximum response length).
	inferenceConfig := &types.InferenceConfiguration{
		MaxTokens: aws.Int32(500), // Allow up to 500 tokens in the response.
	}

	// Build the prompt with movie details.
	prompt := fmt.Sprintf(
		"Provide a short summary of 100 words for the movie '%v', released in %d, which falls under the genre %v.",
		movie.Title, movie.ReleaseYear, movie.Genre,
	)

	// Create the conversation request for Bedrock.
	converseRequest := &bedrockruntime.ConverseInput{
		ModelId: aws.String(MODEL_ID), // AI model to use.
		Messages: []types.Message{
			{
				Role: types.ConversationRoleUser,
				Content: []types.ContentBlock{
					&types.ContentBlockMemberText{Value: prompt},
				},
			},
		},
		System: []types.SystemContentBlock{
			&types.SystemContentBlockMemberText{
				Value: "You are a helpful AI assistant that specializes in movie summaries in 100 words. Just return the summary.",
			},
		},
		InferenceConfig: inferenceConfig,
	}

	// Call Bedrock to generate the summary.
	output, err := BedrockClient.Converse(context.TODO(), converseRequest)
	if err != nil {
		log.Print(err)
		return "", err
	}

	// Extract the generated message.
	outputValue := output.Output.(*types.ConverseOutputMemberMessage).Value
	if len(outputValue.Content) == 0 {
		return "", fmt.Errorf("no summary returned")
	}

	// Retrieve the text content from the response.
	result := outputValue.Content[0].(*types.ContentBlockMemberText).Value
	if result == "" {
		return "", fmt.Errorf("no summary returned")
	}

	return result, nil
}
