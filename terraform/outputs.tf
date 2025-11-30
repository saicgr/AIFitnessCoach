output "api_gateway_invoke_url" {
  description = "API Gateway invocation URL"
  value       = module.api_gateway.invoke_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.lambda.lambda_role_arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.api_gateway.api_gateway_id
}

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
