# Shell Commands Reference

## Stop Running Process

```bash
pkill -f generate_programs
```

## Check if Process is Running

```bash
ps aux | grep python
```

## Run Generation (Foreground)

See output live in terminal:

```bash
cd backend && python3 scripts/generate_programs.py --priority high --no-break
```

## Run in Small Batches (Safer for Memory)

```bash
cd backend && python3 scripts/generate_programs.py --priority high --no-break --limit 10
```

Re-run the same command to continue - it auto-resumes from Supabase.

## Run in Background

```bash
cd backend && nohup python3 scripts/generate_programs.py --priority high --no-break > /tmp/generation.log 2>&1 &
```

Check logs:

```bash
tail -f /tmp/generation.log
```

## Check Progress (SQL)

Count completed variants:

```sql
SELECT COUNT(DISTINCT variant_id) FROM program_variant_weeks;
```

See recent activity:

```sql
SELECT variant_name, week_number, created_at
FROM program_variant_weeks
ORDER BY created_at DESC
LIMIT 10;
```

## Parallel Generation (Laptop Only)

Runs 3 threads simultaneously for faster generation:

```bash
cd backend && python3 scripts/generate_programs_parallel.py --priority medium --threads 3 --no-break
```

With 4 threads (if you have 16GB+ RAM):

```bash
cd backend && python3 scripts/generate_programs_parallel.py --priority high --threads 4 --no-break
```

Dry run to preview:

```bash
cd backend && python3 scripts/generate_programs_parallel.py --priority medium --dry-run
```

## Keyboard Shortcuts

- `Ctrl+C` - Stop running command
- `Ctrl+D` - Exit shell
- `Ctrl+L` - Clear screen
