# AWS Credentials Setup Guide

## Quick Setup (3 Steps)

### Step 1: Get Your AWS Credentials

You need two pieces of information from AWS:
1. **AWS Access Key ID** (looks like: `AKIAIOSFODNN7EXAMPLE`)
2. **AWS Secret Access Key** (looks like: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

**How to get them:**

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Click "Users" → Your username
3. Click "Security credentials" tab
4. Under "Access keys", click "Create access key"
5. Choose "Command Line Interface (CLI)" → Next
6. Download or copy both keys (**Important**: Save the Secret Access Key - you can't view it again!)

### Step 2: Configure AWS Credentials

**Option A: Using AWS CLI (Recommended)**

```bash
# Install AWS CLI
pip3 install --user awscli

# Configure credentials
aws configure
```

When prompted, enter:
- **AWS Access Key ID**: `<your-access-key-id>`
- **AWS Secret Access Key**: `<your-secret-access-key>`
- **Default region name**: `us-east-1`
- **Default output format**: `json`

**Option B: Manual Configuration**

Create the credentials file manually:

```bash
# Create AWS directory
mkdir -p ~/.aws

# Create credentials file
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
EOF

# Create config file
cat > ~/.aws/config << 'EOF'
[default]
region = us-east-1
output = json
EOF

# Secure the files
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

Replace `YOUR_ACCESS_KEY_ID` and `YOUR_SECRET_ACCESS_KEY` with your actual values.

**Option C: Environment Variables (Temporary)**

```bash
# Set for current terminal session only
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"

# Then run the import script
cd backend
python3 scripts/import_s3_data_standalone.py
```

### Step 3: Verify Configuration

```bash
# Test AWS credentials
aws s3 ls s3://ai-fitness-coach/

# Should list:
# 1500+ exercise data.xlsx
# VERTICAL VIDEOS/
```

If you don't have AWS CLI installed, you can skip verification and just run the import script directly.

---

## Running the Import Script

Once credentials are configured:

```bash
cd /Users/saichetangrandhe/AIFitnessCoach/backend
python3 scripts/import_s3_data_standalone.py
```

**Expected output:**

```
============================================================
🚀 S3 Data Import to Supabase
============================================================

📊 Creating s3_video_paths table...
✅ Table created successfully

📊 Creating exercise_library table...
✅ Table created successfully

📹 Scanning S3 for videos...
📊 Found 2000 videos in S3
✅ Imported 100/2000 videos
✅ Imported 200/2000 videos
...
✅ Successfully imported 2000 video paths

📥 Downloading Excel file from S3: 1500+ exercise data.xlsx
📊 Found 1500 exercises in Excel file
📋 Columns: name, body_part, equipment, target, instructions, ...
✅ Imported 100/1500 exercises
✅ Imported 200/1500 exercises
...
✅ Successfully imported 1500 exercises

📊 Creating database views...
✅ Created 4 database views:
   - vw_exercises_with_videos (exercises matched with S3 videos)
   - vw_video_folder_stats (folder statistics)
   - vw_exercises_by_body_part (exercises grouped by body part)
   - vw_exercises_by_equipment (exercises grouped by equipment)

============================================================
✅ Import completed successfully!
============================================================

📊 Summary:
   - Videos imported: 2000
   - Exercises imported: 1500

🔍 Query examples:
   SELECT * FROM vw_exercises_with_videos WHERE body_part = 'chest';
   SELECT * FROM vw_video_folder_stats;
   SELECT * FROM vw_exercises_by_body_part;
```

---

## Troubleshooting

### Error: "Unable to locate credentials"

**Solution**: AWS credentials not configured properly. Follow Step 2 above.

### Error: "An error occurred (AccessDenied)"

**Solution**: Your IAM user needs the following permissions:
- `s3:ListBucket` on `arn:aws:s3:::ai-fitness-coach`
- `s3:GetObject` on `arn:aws:s3:::ai-fitness-coach/*`

Add this IAM policy to your user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::ai-fitness-coach",
        "arn:aws:s3:::ai-fitness-coach/*"
      ]
    }
  ]
}
```

### Error: "No such bucket"

**Solution**: Verify the bucket name is correct: `ai-fitness-coach` in region `us-east-1`

### Script hangs on "Scanning S3 for videos..."

**Solution**: Large number of videos. This is normal - it may take 1-2 minutes to scan 2000+ videos.

---

## Security Best Practices

1. **Never commit credentials to Git**
   - The `.gitignore` already excludes `.env` and AWS config files
   - Never share your Secret Access Key publicly

2. **Use IAM User with Minimal Permissions**
   - Create a dedicated IAM user for this script
   - Only grant S3 read permissions (not write/delete)

3. **Rotate Credentials Regularly**
   - Change access keys every 90 days
   - Delete old/unused access keys

4. **Use AWS Secrets Manager (Production)**
   - For production deployments, use AWS Secrets Manager or IAM roles
   - Don't use long-term credentials in production

---

## What Happens After Import?

Once the import completes, you'll have:

### 1. Database Tables

**`s3_video_paths`** - 2000+ video metadata records
```sql
SELECT * FROM s3_video_paths LIMIT 5;
```

Fields:
- `relative_path` - "Upper Body/Chest/bench_press.mp4"
- `full_s3_key` - "VERTICAL VIDEOS/Upper Body/Chest/bench_press.mp4"
- `folder_path` - "Upper Body/Chest"
- `filename` - "bench_press.mp4"
- `size_mb` - File size in megabytes

**`exercise_library`** - 1500+ exercise records
```sql
SELECT * FROM exercise_library LIMIT 5;
```

Fields:
- `exercise_name` - "Bench Press"
- `body_part` - "chest"
- `equipment` - "barbell"
- `target_muscle` - "pectorals"
- `instructions` - Full exercise instructions
- `gif_url` - Link to animated GIF
- `raw_data` - Complete Excel row as JSON

### 2. Database Views

Query exercises with matched videos:
```sql
SELECT
  exercise_name,
  body_part,
  equipment,
  video_path,
  video_size_mb
FROM vw_exercises_with_videos
WHERE body_part = 'chest'
ORDER BY exercise_name;
```

Get video statistics by folder:
```sql
SELECT
  folder_path,
  video_count,
  total_size_mb,
  avg_size_mb
FROM vw_video_folder_stats
ORDER BY video_count DESC;
```

### 3. API Endpoints

Your FastAPI backend now has these working endpoints:

**Get video URL:**
```bash
curl http://localhost:8000/api/v1/videos/Upper%20Body/Chest/bench_press.mp4
```

**List all videos:**
```bash
curl http://localhost:8000/api/v1/videos/list/
```

**List folders:**
```bash
curl http://localhost:8000/api/v1/videos/folders/
```

---

## Need Help?

If you encounter any issues:

1. Check the error message carefully
2. Verify AWS credentials are correct
3. Ensure S3 bucket name and region are correct
4. Check IAM permissions for your user
5. Look at the script output for specific error details

For AWS-specific issues, refer to [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
