package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/google/uuid"
)

// Item holds individual car's info
type DynamoDBItem struct {
	Model string `json:"model"`
	Color string `json:"color"`
	Make  string `json:"make"`
	Year  string `json:"year"`
}

// addDynamoDBItems Adds items to dynamodb
func addDynamoDBItems(items []DynamoDBItem) {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := dynamodb.New(sess)
	for _, item := range items {
		UUID := uuid.New()
		uuidString := fmt.Sprintf("%s", UUID)
		input := &dynamodb.PutItemInput{
			Item: map[string]*dynamodb.AttributeValue{
				"id": {
					S: aws.String(uuidString),
				},
				"model": {
					S: aws.String(item.Model),
				},
				"color": {
					S: aws.String(item.Color),
				},
				"make": {
					S: aws.String(item.Make),
				},
				"year": {
					N: aws.String(item.Year),
				},
			},
			TableName: aws.String("carTable"),
		}
		_, err := svc.PutItem(input)
		if err != nil {
			log.Fatal(err.Error())
		}
	}
}

// The input type and the output type are defined by the API Gateway.
func handleRequest(event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var items []DynamoDBItem
	err := json.Unmarshal([]byte(event.Body), &items)
	if err != nil {
		return events.APIGatewayProxyResponse{Body: event.Body}, err
	}
	addDynamoDBItems(items)
	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       fmt.Sprint("Successfully added items"),
	}
	return res, nil
}

func main() {
	lambda.Start(handleRequest)
}
