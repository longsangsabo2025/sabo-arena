# 01_schema_changes

## Description
Schema modifications: columns, tables, buckets

## Files in this category
**Total:** 25 migration files

## Migrations
- `add_delivered_at_column.sql`
- `add_elo_history_columns.sql`
- `add_evidence_urls_column.sql`
- `ADD_INITIALIZATION_COLUMNS.sql`
- `add_missing_platform_settings_and_voucher_templates.sql`
- `add_redemption_code_column.sql`
- `add_score_to_challenges.sql`
- `add_transactions_columns.sql`
- `add_used_status_to_vouchers.sql`
- `create_club_payment_settings_table.sql`
- `create_club_photos_table.sql`
- `create_share_analytics_tables.sql`
- `create_tournament_covers_bucket.sql`
- `create_tournament_result_history_table.sql`
- `deploy_auto_club_membership.sql`
- `FINAL_SQL_FIX.sql`
- `fix_add_race_to_column.sql`
- `fix_all_voucher_system.sql`
- `fix_claim_pending_referral.sql`
- `fix_like_count_migration.sql`
- `fix_rls_spa_redemptions.sql`
- `fix_table_reservation_user_relation.sql`
- `insert_payment_methods.sql`
- `quick_like_fix.sql`
- `sabo_arena_basic_migration_20251023_143804.sql`

## How to Apply

```bash
# Review migration before applying
cat 01_schema_changes/<migration-file>.sql

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
