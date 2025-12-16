# 03_functions_triggers

## Description
Database functions and triggers

## Files in this category
**Total:** 7 migration files

## Migrations
- `create_notification_functions.sql`
- `create_rank_approval_function_FIXED.sql`
- `create_rank_approval_function.sql`
- `fix_tournament_started_trigger.sql`
- `setup_notification_tables.sql`
- `setup_voucher_notification_system.sql`
- `update_get_leaderboard_with_avatar.sql`

## How to Apply

```bash
# Review migration before applying
cat 03_functions_triggers/<migration-file>.sql

# Apply to database (using psql or Supabase CLI)
psql -U postgres -d sabo_arena -f <migration-file>.sql

# Or using Supabase CLI
supabase db push <migration-file>.sql
```

## Rollback Strategy

⚠️ **Important:** Always test in development environment first!

- Create backups before applying migrations
- Document rollback SQL for each migration
- Test rollback procedures

---
Generated: 2025-11-22 21:25:26
