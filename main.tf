provider "aws" {
  region = var.region
}

data "aws_s3_bucket_object" "getCar_lambda" {
  bucket = var.s3_bucket
  key    = "getCar.zip"
}

data "aws_s3_bucket_object" "addCars_lambda" {
  bucket = var.s3_bucket
  key    = "addCars.zip"
}

# create DynamoDB table
resource "aws_dynamodb_table" "car" {
  name              = "carTable"
  read_capacity     = 5
  write_capacity    = 5
  hash_key          = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "cars"
}

resource "aws_api_gateway_resource" "resources" {
  path_part   = "cars"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "{id}"
  parent_id   = aws_api_gateway_resource.resources.id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method1" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resources.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "method2" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.ID" = true
  }
}

resource "aws_api_gateway_method" "method3" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resources.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resources.id
  http_method             = aws_api_gateway_method.method1.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "id-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "car-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resources.id
  http_method             = aws_api_gateway_method.method3.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.add_car_lambda.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_add_car_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add_car_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "lambda" {
  s3_bucket         = data.aws_s3_bucket_object.getCar_lambda.bucket
  s3_key            = data.aws_s3_bucket_object.getCar_lambda.key
  source_code_hash  = md5(data.aws_s3_bucket_object.getCar_lambda.etag)
  function_name     = "getCar"
  role              = aws_iam_role.role.arn
  handler           = "getCar"
  runtime           = "go1.x"
}

resource "aws_lambda_function" "add_car_lambda" {
  s3_bucket         = data.aws_s3_bucket_object.addCars_lambda.bucket
  s3_key            = data.aws_s3_bucket_object.addCars_lambda.key
  source_code_hash  = md5(data.aws_s3_bucket_object.addCars_lambda.etag)
  function_name     = "addCars"
  role              = aws_iam_role.role.arn
  handler           = "addCars"
  runtime           = "go1.x"
}

# This resource defines the URL of the API Gateway.
resource "aws_api_gateway_deployment" "car_v1" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration.id-integration,
    aws_api_gateway_integration.car-integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}

# IAM
resource "aws_iam_role" "role" {
  name = "get_car"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "policy" {
  name   = "lambda-dynamodb-policy"
  policy = templatefile("${path.module}/templates/iam_policy.tmpl", { s3_bucket = var.s3_bucket, resource = aws_dynamodb_table.car.arn }) 
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# Set the generated URL as an output. Run `terraform output url` to get this.
output "api_url" {
  value = "${aws_api_gateway_deployment.car_v1.invoke_url}${aws_api_gateway_resource.resources.path}"
}
