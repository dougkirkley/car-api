# Car API

API for adding cars to a database and retrieving those cars' information.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You will need AWS env variables added to the CI variables for the project

The AWS credentials used during testing was the administrator group policy in AWS.

### Installing Locally

To install for local development on Mac via Homebrew
```
brew install awscli

brew install go

brew install terraform
```

## Testing the API
You can run testing locally via `make test`

### Local Deployment
For local deployment only, you will need to create the s3 bucket manually

You will need to export the following variables for local deployment to work properly:
- $S3_BUCKET

To deploy, run `make S3_BUCKET=$S3_BUCKET` 

in the root directory of the project.

## Authors

* **Douglass Kirkley** - *Initial work* - [car-api](https://github.com/dougkirkley)
