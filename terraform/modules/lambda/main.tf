resource "aws_ecr_repository" "lambda_repo" {
  name                 = "${var.lambda_function_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.lambda_function_name}-ecr-repo"
  }
}

resource "aws_lambda_function" "api" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment {
    variables = {
      SUPABASE_URL              = var.supabase_url
      SUPABASE_KEY              = var.supabase_anon_key
      SUPABASE_SERVICE_ROLE_KEY = var.supabase_service_role_key
      DATABASE_URL              = var.database_url
      OPENAI_API_KEY            = var.openai_api_key
      OPENAI_MODEL              = "gpt-4"
      OPENAI_EMBEDDING_MODEL    = "text-embedding-3-small"
      OPENAI_MAX_TOKENS         = "2000"
      OPENAI_TEMPERATURE        = "0.7"
      CHROMA_CLOUD_HOST         = var.chroma_cloud_host
      CHROMA_CLOUD_API_KEY      = var.chroma_cloud_api_key
      S3_BUCKET_NAME            = var.s3_bucket_name
      AWS_REGION_NAME           = var.aws_region
      DEBUG                     = "false"
    }
  }

  reserved_concurrent_executions = 10

  tags = {
    Name        = var.lambda_function_name
    Environment = var.environment
  }

  # Ignore image changes since we'll update via CI/CD
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.lambda_function_name}-logs"
  }
}
