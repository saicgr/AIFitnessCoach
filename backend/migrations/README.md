# Database Migration to Supabase

This directory contains migration scripts and SQL files for migrating the FitWiz from DuckDB to Supabase Postgres.

## Overview

The migration involves:
1. **Schema Creation**: Creating all tables in Supabase Postgres with proper types and constraints
2. **Data Migration**: Transferring existing data from DuckDB to Postgres
3. **Auth Integration**: Setting up Supabase Authentication for user management
4. **Row Level Security**: Implementing RLS policies to secure user data

## Prerequisites

1. **Supabase Project**: You need an active Supabase project
2. **Credentials**: Add these to your `.env` file:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-key
   SUPABASE_DB_PASSWORD=your-db-password
   DATABASE_URL=postgresql+asyncpg://postgres:password@db.your-project.supabase.co:5432/postgres
   ```

3. **Python Dependencies**: Already installed via requirements.txt:
   - `supabase==2.3.4`
   - `psycopg2-binary==2.9.9`
   - `asyncpg==0.29.0`

## Migration Steps

### Step 1: Create Postgres Schema

Run the SQL migration script in your Supabase SQL Editor:

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open and run [001_initial_schema.sql](./001_initial_schema.sql)

This will create:
- ✅ All database tables (users, exercises, workouts, etc.)
- ✅ Indexes for performance
- ✅ Foreign key constraints
- ✅ Row Level Security (RLS) policies
- ✅ Integration with Supabase Auth

### Step 2: Verify Schema

After running the SQL script, verify the tables were created:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see all tables:
- users
- exercises
- workouts
- workout_logs
- performance_logs
- strength_records
- weekly_volumes
- chat_history
- injuries
- user_metrics
- injury_history
- workout_changes

### Step 3: Migrate Data (Optional)

If you have existing data in DuckDB, migrate it:

```bash
cd backend
python3 migrations/migrate_duckdb_to_postgres.py
```

This script will:
- Read all data from `./data/fitness_coach.duckdb`
- Convert integer IDs to UUIDs
- Parse JSON fields correctly
- Migrate data to Supabase Postgres
- Preserve relationships between tables

**Note**: The migration script handles:
- ✅ ID mapping (integer → UUID)
- ✅ JSON field parsing
- ✅ Foreign key preservation
- ✅ Timestamp conversion
- ✅ Transaction safety (rollback on error)

### Step 4: Update Application Code

The application is already configured to use Supabase. Key files:

- [core/config.py](../core/config.py) - Supabase configuration
- [core/supabase_client.py](../core/supabase_client.py) - Database and auth client
- [.env](../.env) - Environment variables

## Database Schema Changes

### Key Differences from DuckDB

1. **UUIDs instead of Integer IDs**
   - DuckDB: `id INTEGER PRIMARY KEY`
   - Postgres: `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()`

2. **JSON vs JSONB**
   - DuckDB: `VARCHAR` fields storing JSON strings
   - Postgres: `JSONB` for efficient JSON storage and querying

3. **Timestamps**
   - DuckDB: `TIMESTAMP`
   - Postgres: `TIMESTAMPTZ` (timezone-aware)

4. **Text Fields**
   - DuckDB: `VARCHAR`
   - Postgres: `TEXT` for long content, `VARCHAR` for short

### New Features with Supabase

1. **Supabase Auth Integration**
   - Users table has `auth_id` field linking to `auth.users`
   - Automatic user management via Supabase Auth
   - Password reset, email verification, etc.

2. **Row Level Security (RLS)**
   - Users can only access their own data
   - Policies automatically enforce data isolation
   - Example: `SELECT * FROM workouts` only returns current user's workouts

3. **Real-time Subscriptions** (if needed)
   - Subscribe to database changes
   - Get instant updates when data changes
   - Useful for live workout tracking

## Using Supabase Auth

### Sign Up

```python
from core.supabase_client import get_auth

auth = get_auth()
response = await auth.sign_up(
    email="user@example.com",
    password="securepassword123",
    metadata={"name": "John Doe"}
)
```

### Sign In

```python
response = await auth.sign_in(
    email="user@example.com",
    password="securepassword123"
)

# Get access token
access_token = response.session.access_token
```

### Get Current User

```python
user = await auth.get_user(access_token)
print(f"User ID: {user.id}")
print(f"Email: {user.email}")
```

### Protected Routes

Use JWT tokens to protect API endpoints:

```python
from fastapi import Depends, HTTPException, Header
from core.supabase_client import get_auth

async def get_current_user(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")

    token = authorization.replace("Bearer ", "")
    auth = get_auth()

    try:
        user = await auth.get_user(token)
        return user
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

# Use in routes
@app.get("/workouts")
async def get_workouts(user = Depends(get_current_user)):
    # user.id is the Supabase auth user ID
    # Query workouts for this user
    ...
```

## Database Access Patterns

### Using SQLAlchemy (Async)

```python
from sqlalchemy import select
from core.supabase_client import get_db_session

async def get_user_workouts(user_id: str):
    async with get_db_session() as session:
        result = await session.execute(
            select(Workout).where(Workout.user_id == user_id)
        )
        return result.scalars().all()
```

### Using Supabase Client (Direct)

```python
from core.supabase_client import get_supabase

supabase = get_supabase()

# Query with RLS automatically applied
response = supabase.client.table('workouts').select('*').execute()
workouts = response.data
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Supabase Postgres
**Solution**:
- Check your `DATABASE_URL` format: `postgresql+asyncpg://postgres:PASSWORD@db.PROJECT.supabase.co:5432/postgres`
- Verify database password in Supabase dashboard
- Check if your IP is allowed (Supabase allows all by default)

### RLS Blocking Queries

**Problem**: Queries return empty results
**Solution**:
- Ensure you're authenticated with a valid JWT
- Check RLS policies in Supabase dashboard
- Temporarily disable RLS for testing: `ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;`

### Migration Errors

**Problem**: Migration script fails
**Solution**:
- Check DuckDB file exists: `./data/fitness_coach.duckdb`
- Verify Postgres connection
- Check logs for specific error
- Run migration in transaction (already implemented)

## Rollback

If you need to rollback:

1. **Drop all tables**:
```sql
DROP TABLE IF EXISTS workout_changes CASCADE;
DROP TABLE IF EXISTS injury_history CASCADE;
DROP TABLE IF EXISTS user_metrics CASCADE;
DROP TABLE IF EXISTS injuries CASCADE;
DROP TABLE IF EXISTS chat_history CASCADE;
DROP TABLE IF EXISTS weekly_volumes CASCADE;
DROP TABLE IF EXISTS strength_records CASCADE;
DROP TABLE IF EXISTS performance_logs CASCADE;
DROP TABLE IF EXISTS workout_logs CASCADE;
DROP TABLE IF EXISTS workouts CASCADE;
DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

2. **Re-run migration**: Execute `001_initial_schema.sql` again

## Performance Tips

1. **Indexes**: Already created on foreign keys and frequently queried columns
2. **Connection Pooling**: SQLAlchemy engine uses pool (10 connections, 20 max overflow)
3. **Batch Operations**: Use `executemany()` for bulk inserts
4. **JSONB Queries**: Use JSONB operators for efficient querying:
   ```sql
   SELECT * FROM users WHERE preferences->>'theme' = 'dark';
   ```

## Security Best Practices

1. **Never expose service_role key**: Only use `anon` or `authenticated` keys in client
2. **Use RLS**: Always keep Row Level Security enabled
3. **JWT Validation**: Validate tokens on every protected endpoint
4. **Password Policy**: Enforce strong passwords via Supabase Auth settings
5. **HTTPS Only**: Always use HTTPS for production

## Next Steps

After migration:

1. ✅ Test all API endpoints
2. ✅ Verify RLS policies work correctly
3. ✅ Update frontend to use Supabase Auth
4. ✅ Set up backup schedule in Supabase dashboard
5. ✅ Configure email templates for auth emails
6. ✅ Set up monitoring and alerts

## Support

- **Supabase Docs**: https://supabase.com/docs
- **SQLAlchemy Async**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- **Supabase Python Client**: https://github.com/supabase-community/supabase-py
