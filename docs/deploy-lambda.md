# Deploying FitWiz to AWS Lambda

Complete guide for deploying the FastAPI backend to AWS Lambda using Terraform.

## Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** configured (`aws configure`)
3. **Terraform** >= 1.5.0 installed
4. **Docker** installed (for building Lambda container images)
5. **Supabase Project** with database migrated (see [supabase-migration.md](supabase-migration.md))
6. **Chroma Cloud Account** (see [chroma-cloud.md](chroma-cloud.md))

## Step 1: Configure Environment Variables

Create `terraform/terraform.tfvars` from the example:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Update with your actual values:
```hcl
# Get from Supabase dashboard
supabase_url = "https://yourproject.supabase.co"
supabase_anon_key = "eyJ..."
supabase_service_role_key = "eyJ..."
database_url = "postgresql+asyncpg://postgres:password@db.yourproject.supabase.co:5432/postgres"

# Get from OpenAI dashboard
openai_api_key = "sk-..."

# Get from Chroma Cloud dashboard
chroma_cloud_api_key = "..."
```

## Step 2: Create Terraform State Backend

First time only - create S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket for state
aws s3 mb s3://ai-fitness-coach-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ai-fitness-coach-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name ai-fitness-coach-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Step 3: Initialize Terraform

```bash
cd terraform
terraform init
```

This downloads AWS provider and initializes remote state backend.

## Step 4: Build Docker Image Locally (Optional)

Test the Docker build locally first:

```bash
cd ../backend
docker build -t ai-fitness-coach-local .
docker run -p 9000:8080 ai-fitness-coach-local

# In another terminal, test it
curl "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"resource":"GET /api/v1/health/"}'
```

## Step 5: Deploy Infrastructure

```bash
cd ../terraform

# Preview changes
terraform plan

# Apply changes
terraform apply
```

Terraform will:
1. Create ECR repository for Docker images
2. Create Lambda function (1GB RAM, 60s timeout)
3. Create API Gateway REST API
4. Set up IAM roles and permissions
5. Configure CloudWatch logs

Note the outputs:
```
api_gateway_invoke_url = "https://abc123.execute-api.us-east-1.amazonaws.com/production"
```

## Step 6: Build and Push Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and tag
cd ../backend
docker build -t ai-fitness-coach-api .
docker tag ai-fitness-coach-api:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/ai-fitness-coach-api-repo:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/ai-fitness-coach-api-repo:latest
```

## Step 7: Update Lambda Function

```bash
cd ../terraform
terraform apply  # Updates Lambda to use new image
```

## Step 8: Test the API

```bash
API_URL="https://abc123.execute-api.us-east-1.amazonaws.com/production"

# Health check
curl $API_URL/api/v1/health/

# Test protected endpoint (needs Supabase JWT)
curl -H "Authorization: Bearer <jwt-token>" \
  $API_URL/api/v1/workouts-db/
```

## Updating the Deployment

When you make code changes:

```bash
# 1. Build new Docker image
cd backend
docker build -t ai-fitness-coach-api .

# 2. Tag and push to ECR
docker tag ai-fitness-coach-api:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/ai-fitness-coach-api-repo:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/ai-fitness-coach-api-repo:latest

# 3. Lambda automatically pulls new image within ~5 minutes
# Or force update:
aws lambda update-function-code \
  --function-name ai-fitness-coach-api \
  --image-uri <account-id>.dkr.ecr.us-east-1.amazonaws.com/ai-fitness-coach-api-repo:latest
```

## CI/CD with GitHub Actions

See [.github/workflows/deploy.yml](.github/workflows/deploy.yml).

Configure secrets in GitHub repo settings:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_URL`
- `OPENAI_API_KEY`
- `CHROMA_CLOUD_API_KEY`

Push to `main` branch to auto-deploy.

## Monitoring

View logs in CloudWatch:
```bash
aws logs tail /aws/lambda/ai-fitness-coach-api --follow
```

Or use AWS Console → CloudWatch → Log Groups.

## Troubleshooting

See [troubleshooting.md](troubleshooting.md).

## Cost Estimation

- Lambda: $5-20/month (1M requests, 1GB RAM, 30s avg)
- API Gateway: $3.50/month (1M requests)
- ECR: $0.10/month (1GB storage)
- CloudWatch Logs: $2-5/month
- **Total**: ~$10-30/month for low-medium traffic
