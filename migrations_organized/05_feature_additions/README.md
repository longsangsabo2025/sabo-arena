# 05_feature_additions

## Description
Feature-specific migrations

## Files in this category
**Total:** 10 migration files

## Migrations
- `add_source_match_tracking.sql`
- `add_tournament_auto_post_feature.sql`
- `auto_fill_cross_finals_players.sql`
- `fix_auto_post_semifinals_finals_only.sql`
- `fix_trigger_remove_round_name.sql`
- `loyalty_program_system.sql`
- `pending_referrals_tracking.sql`
- `promotion_analytics_system.sql`
- `tournament_prize_voucher_system.sql`
- `welcome_voucher_campaign.sql`

## How to Apply

```bash
# Review migration before applying
cat 05_feature_additions/<migration-file>.sql

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
