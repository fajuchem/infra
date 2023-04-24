output "apigwy_url" {
  description = "URL for API Gateway"

  value = aws_apigatewayv2_stage.lambda.invoke_url
}
