package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

// Item holds individual car's info
type DynamoDBItem struct {
	ID    string `json:"id"`
	Model string `json:"model"`
	Color string `json:"color"`
	Make  string `json:"make"`
	Year  string `json:"year"`
}

// getItem gets a table item
func getItem(id string) []byte {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := dynamodb.New(sess)
	input := &dynamodb.GetItemInput{
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				S: aws.String(id),
			},
		},
		TableName: aws.String("carTable"),
	}
	result, _ := svc.GetItem(input)
	
    item := DynamoDBItem{}
	err := dynamodbattribute.UnmarshalMap(result.Item, &item)
    if err != nil {
         panic(fmt.Sprintf("failed to unmarshal Dynamodb Scan Items, %v", err))
    }
	
	if len(item.ID) == 0 {
	    res, _ := json.Marshal(fmt.Sprintf("Error, %s, not found", id))
		return res
	}
	
	res, _ := json.Marshal(item)
	return res
}

func getItems() []byte {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
    svc := dynamodb.New(sess)
    input := &dynamodb.ScanInput{
    TableName: aws.String("carTable"),
    }
	result, err := svc.Scan(input)
	if err != nil {
		log.Print(err.Error())
	}
	items := []DynamoDBItem{}
	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &items)
    if err != nil {
         panic(fmt.Sprintf("failed to unmarshal Dynamodb Scan Items, %v", err))
	}
	res, _ := json.Marshal(items)

	return res
}



// The input type and the output type are defined by the API Gateway.
func handleRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id, ok := req.PathParameters["id"]
	log.Print(ok)
	if ok {
		result := getItem(id)
		if strings.Contains(string(result), "Error") {
		    res := events.APIGatewayProxyResponse{
				StatusCode: http.StatusNotFound,
				Headers:    map[string]string{"Content-Type": "application/json"},
				Body:       fmt.Sprintf("%s", result),
			}	
			return res, nil
		}
	    res := events.APIGatewayProxyResponse{
            StatusCode: http.StatusOK,
		    Headers:    map[string]string{"Content-Type": "application/json"},
			Body:       fmt.Sprintf("%s", result),
		}
		return res, nil
	} else {
	    result := getItems()
	    res := events.APIGatewayProxyResponse{
		    StatusCode: http.StatusOK,
		    Headers:    map[string]string{"Content-Type": "application/json"},
		    Body:       fmt.Sprintf("%s", result),
	    }
		return res, nil
	}
}

func main() {
	lambda.Start(handleRequest)
}
