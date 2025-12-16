# 02_rls_policies

## Description
Row-level security policy fixes

## Files in this category
**Total:** 6 migration files

## Migrations
- `fix_elo_history_rls.sql`
- `fix_rls_policies.sql`
- `fix_tournament_rls_for_bracket.sql`
- `fix_tournament_voucher_rls.sql`
- `fix_voucher_rls_policies.sql`
- `manual_deploy_smart_rls.sql`

## How to Apply

```bash
# Review migration before applying
cat 02_rls_policies/<migration-file>.sql

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
