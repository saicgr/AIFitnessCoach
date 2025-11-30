terraform {
  backend "s3" {
    bucket         = "ai-fitness-coach-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ai-fitness-coach-terraform-locks"
  }
}
