variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory allocation for Lambda (MB)"
  type        = number
}

variable "lambda_timeout" {
  description = "Timeout for Lambda (seconds)"
  type        = number
}

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "PostgreSQL database URL"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "chroma_cloud_host" {
  description = "Chroma Cloud host"
  type        = string
}

variable "chroma_cloud_api_key" {
  description = "Chroma Cloud API key"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket for videos"
  type        = string
}
