Frontend
	•	Web: React app hosted on Vercel (or similar)
	•	Mobile (later): React Native / Flutter talking to the same APIs

Auth & Data
	•	Supabase Auth: user sign-up / login → JWT
	•	Supabase Postgres:
	•	users, exercises, exercise_videos (metadata + S3 key / URL)
	•	workouts, user_progress, food_photos (for AI nutrition coach)
	•	maybe chat_history, etc.

Backend (API layer)
	•	FastAPI backend
	•	Deployed on AWS Lambda behind API Gateway - needs done
	•	Responsibilities:
	•	Verify Supabase JWT DONE
	•	Read/write Supabase Postgres DONE
	•	Generate S3 pre-signed URLs for uploads DONE
	•	Call Chroma Cloud for vector search (RAG) DONE
	•	Call LLM provider (OpenAI / Anthropic etc.) DONE
	•	Build responses for AI fitness coach, program logic, etc. DONE

Storage & Media
	•	Existing S3 bucket: arn:aws:s3:::ai-fitness-coach DONE
	•	Stores fitness videos (already uploaded) DONE
	•	Stores user-uploaded images for calorie/macro tracking DONE
	<!-- •	CloudFront (to be added):
	•	CDN in front of S3 for fast, cheaper video/image delivery
	•	App uses CloudFront URLs for streaming content -->

Vector DB / RAG DONE
	•	Chroma Cloud as managed vector DB 
	•	Stores embeddings for:
	•	exercise descriptions
	•	AI coaching snippets
	•	user meal logs, etc.
	•	Backend queries Chroma with user_id + question to build context

AI Models
	•	External LLM provider:
	•	OpenAI / Anthropic / etc. via HTTP APIs DONE
	•	Used by Lambda backend (FastAPI handlers)

Infra & Deployment
	•	Terraform:
	•	Manages AWS resources:
	•	API Gateway, Lambda, IAM roles
	•	S3 (permissions, maybe extra buckets)
	•	CloudFront
	•	Chroma VPC endpoints if ever needed, etc.
	•	State backend: S3 + DynamoDB (as above)
	•	GitHub + CI/CD:
	•	Repo contains:
	•	backend/ FastAPI code
	•	infra/ Terraform
	•	docs/ for “how to” (Terraform, AWS, Supabase, Chroma)
	•	GitHub Actions pipelines:
	•	Build & deploy backend to Lambda
	•	Run terraform fmt/plan/apply (probably on main branch only)
	•	Deploy web app to Vercel

Observability & Logs
	•	AWS CloudWatch:
	•	Lambda logs, metrics, alarms
	•	API Gateway access logs (optional)
	•	Supabase Logs:
	•	DB queries, auth events, errors