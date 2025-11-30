# S3 Data Import - Quick Start

## 🚀 2-Minute Setup

### Step 1: Get AWS Credentials (1 minute)

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Click: **Users** → **Your username** → **Security credentials**
3. Click: **Create access key** → Choose **CLI** → **Create**
4. **Copy both keys** (Access Key ID + Secret Access Key)

### Step 2: Run Setup Script (30 seconds)

```bash
cd backend/scripts
./setup_aws.sh
```

Enter your credentials when prompted. That's it!

### Step 3: Import Data (1-2 minutes)

```bash
cd ..
python3 scripts/import_s3_data_standalone.py
```

Wait for completion. You'll see:
- ✅ Tables created
- ✅ 2000 videos imported
- ✅ 1500 exercises imported
- ✅ 4 views created

---

## Alternative: Manual Setup

If you prefer manual setup:

```bash
# Create AWS config
mkdir -p ~/.aws

cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
EOF

cat > ~/.aws/config << 'EOF'
[default]
region = us-east-1
output = json
EOF

chmod 600 ~/.aws/credentials ~/.aws/config
```

Then run the import:
```bash
cd backend
python3 scripts/import_s3_data_standalone.py
```

---

## ✅ What You Get

After import completes:

### 1. Database Tables
- `s3_video_paths` - 2000+ video metadata
- `exercise_library` - 1500+ exercises

### 2. Database Views
- `vw_exercises_with_videos` - Exercises matched with videos
- `vw_video_folder_stats` - Video statistics by folder
- `vw_exercises_by_body_part` - Exercises by body part
- `vw_exercises_by_equipment` - Exercises by equipment

### 3. Working API Endpoints
- `GET /api/v1/videos/{path}` - Get presigned video URL
- `GET /api/v1/videos/list/` - List all videos
- `GET /api/v1/videos/folders/` - List video folders

---

## 🔍 Quick Test

After import, test your data:

```sql
-- View all imported videos
SELECT COUNT(*) FROM s3_video_paths;

-- View all exercises
SELECT COUNT(*) FROM exercise_library;

-- Get chest exercises with videos
SELECT * FROM vw_exercises_with_videos
WHERE body_part = 'chest'
LIMIT 5;

-- Video statistics
SELECT * FROM vw_video_folder_stats
ORDER BY video_count DESC;
```

Or test the API:
```bash
curl http://localhost:8000/api/v1/videos/folders/
```

---

## 📚 Full Documentation

- [AWS Setup Guide](AWS_SETUP_GUIDE.md) - Detailed setup instructions
- [README](README.md) - Import script documentation

---

## ⚠️ Troubleshooting

**Error: "Unable to locate credentials"**
→ Run `./setup_aws.sh` again

**Error: "Access Denied"**
→ Your IAM user needs S3 read permissions (see AWS_SETUP_GUIDE.md)

**Script hangs**
→ Normal for large datasets. Wait 1-2 minutes.

---

**Need help?** Check [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) for detailed troubleshooting.
