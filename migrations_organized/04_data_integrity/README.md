# 04_data_integrity

## Description
Data integrity: foreign keys, constraints

## Files in this category
**Total:** 10 migration files

## Migrations
- `fix_club_roles_constraint.sql`
- `fix_clubs_users_fk.sql`
- `fix_clubs_users_relationship.sql`
- `fix_posts_club_fk.sql`
- `fix_voucher_status_constraint.sql`
- `fix_voucher_status_enum.sql`
- `migration_1_critical_security_fixes.sql`
- `migration_2_data_integrity_fixes.sql`
- `migration_3_performance_optimization.sql`
- `migration_smart_social_rls.sql`

## How to Apply

```bash
# Review migration before applying
cat 04_data_integrity/<migration-file>.sql

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
