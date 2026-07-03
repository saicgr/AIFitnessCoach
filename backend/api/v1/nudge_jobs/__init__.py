"""Individual push-nudge cron jobs, extracted as modules.

`push_nudge_cron.py` is 4,400+ lines; new jobs land here instead of growing
it further. Each module exposes an async `job_*` coroutine with the standard
`(supabase, notif_svc, users) -> int` signature and is registered in the
jobs list inside `run_push_nudge_cron`.
"""
