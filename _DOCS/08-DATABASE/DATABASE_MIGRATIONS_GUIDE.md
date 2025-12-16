# SABO Arena Database Migrations - Organization Guide

## Migration Directories Structure

### `sql_migrations/` (47 files)
Core database schema migrations and fixes

**Categories:**
- **Schema Changes**: Column additions, table creation
- **RLS Policies**: Row-level security fixes
- **Functions**: Stored procedures and triggers
- **Data Integrity**: Foreign key fixes, constraints

### `supabase_migrations/` (10 files)
Feature-specific migrations for Supabase deployment

**Categories:**
- **Tournament Features**: Prize systems, auto-posting
- **User Features**: Referrals, loyalty, welcome campaigns
- **Analytics**: Promotion tracking
- **Source Tracking**: Match origin tracking

## Migration Naming Convention

### Current State
Mixed naming patterns:
- `add_*.sql` - Column/feature additions
- `fix_*.sql` - Bug fixes and corrections
- `create_*.sql` - New table/bucket creation
- `setup_*.sql` - System setup migrations
- Numbered migrations: `migration_1_*.sql`, `migration_2_*.sql`

### Recommended Convention
```
YYYYMMDD_HHMMSS_descriptive_name.sql
```

## Applied vs Pending Migrations

### How to Track
1. Check Supabase migration history
2. Review applied migrations in production
3. Document pending migrations

### Migration Status
⚠️ **Action Required**: Audit which migrations have been applied

## Next Steps

1. **Consolidate**: Merge similar migrations
2. **Document**: Add README for each migration type
3. **Archive**: Move old/obsolete migrations to `_archived_migrations/`
4. **Version**: Implement proper versioning system

## Best Practices

- Always backup before running migrations
- Test in development environment first
- Document rollback procedures
- Use transactions for reversibility
- Track migration dependencies

---
Generated: 2025-11-22
Last Updated: 2025-11-22
