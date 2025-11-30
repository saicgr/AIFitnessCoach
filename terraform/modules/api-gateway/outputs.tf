output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

output "invoke_url" {
  description = "API Gateway invocation URL"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "stage_name" {
  description = "Name of the deployment stage"
  value       = aws_api_gateway_stage.api.stage_name
}
