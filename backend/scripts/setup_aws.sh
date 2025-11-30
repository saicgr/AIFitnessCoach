#!/bin/bash

# AWS Credentials Setup Script for S3 Data Import
# This script helps you configure AWS credentials interactively

set -e  # Exit on error

echo "============================================================"
echo "🔐 AWS Credentials Setup"
echo "============================================================"
echo ""

# Check if AWS directory exists
if [ -d "$HOME/.aws" ]; then
    echo "⚠️  AWS configuration directory already exists: ~/.aws"
    echo ""
    read -p "Do you want to overwrite existing credentials? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "❌ Setup cancelled."
        exit 0
    fi
fi

echo "📝 You'll need your AWS credentials from the IAM Console."
echo "   Get them at: https://console.aws.amazon.com/iam/"
echo ""
echo "   1. Go to IAM → Users → Your username"
echo "   2. Security credentials tab"
echo "   3. Create access key → CLI"
echo "   4. Copy both keys"
echo ""

# Prompt for Access Key ID
read -p "Enter AWS Access Key ID: " access_key
if [ -z "$access_key" ]; then
    echo "❌ Access Key ID cannot be empty"
    exit 1
fi

# Prompt for Secret Access Key (hidden input)
read -s -p "Enter AWS Secret Access Key: " secret_key
echo ""
if [ -z "$secret_key" ]; then
    echo "❌ Secret Access Key cannot be empty"
    exit 1
fi

# Prompt for region (default: us-east-1)
read -p "Enter AWS Region (default: us-east-1): " region
region=${region:-us-east-1}

echo ""
echo "📁 Creating AWS configuration..."

# Create .aws directory
mkdir -p "$HOME/.aws"

# Create credentials file
cat > "$HOME/.aws/credentials" << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF

# Create config file
cat > "$HOME/.aws/config" << EOF
[default]
region = $region
output = json
EOF

# Secure the files (only user can read/write)
chmod 600 "$HOME/.aws/credentials"
chmod 600 "$HOME/.aws/config"

echo "✅ AWS credentials configured successfully!"
echo ""
echo "📍 Configuration files created:"
echo "   - ~/.aws/credentials"
echo "   - ~/.aws/config"
echo ""

# Test connection (if AWS CLI is available)
if command -v aws &> /dev/null; then
    echo "🔍 Testing S3 connection..."
    if aws s3 ls s3://ai-fitness-coach/ &> /dev/null; then
        echo "✅ Successfully connected to S3 bucket: ai-fitness-coach"
        echo ""
        echo "📦 Bucket contents:"
        aws s3 ls s3://ai-fitness-coach/
    else
        echo "⚠️  Could not list S3 bucket. Check your permissions."
        echo "   Your IAM user needs s3:ListBucket and s3:GetObject permissions."
    fi
else
    echo "ℹ️  AWS CLI not installed - skipping connection test"
    echo "   Install with: pip3 install --user awscli"
fi

echo ""
echo "============================================================"
echo "✅ Setup Complete!"
echo "============================================================"
echo ""
echo "Next step: Run the import script"
echo ""
echo "  cd /Users/saichetangrandhe/AIFitnessCoach/backend"
echo "  python3 scripts/import_s3_data_standalone.py"
echo ""
