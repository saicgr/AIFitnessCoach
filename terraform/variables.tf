variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "ai-fitness-coach-api"
}

variable "lambda_memory_size" {
  description = "Memory allocation for Lambda function (MB)"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function (seconds)"
  type        = number
  default     = 60
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "ai-fitness-coach-api-gateway"
}

# Supabase Configuration
variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous/public key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key (admin access)"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "PostgreSQL database connection URL (asyncpg format)"
  type        = string
  sensitive   = true
}

# OpenAI Configuration
variable "openai_api_key" {
  description = "OpenAI API key for GPT-4"
  type        = string
  sensitive   = true
}

# Chroma Cloud Configuration
variable "chroma_cloud_host" {
  description = "Chroma Cloud host URL"
  type        = string
  default     = "api.trychroma.com"
}

variable "chroma_cloud_api_key" {
  description = "Chroma Cloud API key"
  type        = string
  sensitive   = true
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "S3 bucket name for fitness videos"
  type        = string
  default     = "ai-fitness-coach"
}
