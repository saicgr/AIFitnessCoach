terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AIFitnessCoach"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Lambda Function Module
module "lambda" {
  source = "./modules/lambda"

  environment          = var.environment
  aws_region           = var.aws_region
  lambda_function_name = var.lambda_function_name
  lambda_memory_size   = var.lambda_memory_size
  lambda_timeout       = var.lambda_timeout

  # Environment variables for Lambda
  supabase_url              = var.supabase_url
  supabase_anon_key         = var.supabase_anon_key
  supabase_service_role_key = var.supabase_service_role_key
  database_url              = var.database_url
  openai_api_key            = var.openai_api_key
  chroma_cloud_host         = var.chroma_cloud_host
  chroma_cloud_api_key      = var.chroma_cloud_api_key
  s3_bucket_name            = var.s3_bucket_name
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"

  environment         = var.environment
  api_name            = var.api_gateway_name
  lambda_function_arn = module.lambda.lambda_function_arn
  lambda_function_name = module.lambda.lambda_function_name
  aws_region          = var.aws_region
}

# S3 Bucket Policy Update (for existing bucket)
resource "aws_s3_bucket_policy" "video_bucket_policy" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaReadVideos"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda.lambda_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}
