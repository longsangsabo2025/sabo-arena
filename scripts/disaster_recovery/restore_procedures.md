# Database Restore Procedures

## Restore from Supabase Automated Backup

### Via Supabase Dashboard
1. Go to Supabase Dashboard → Database → Backups
2. Select backup point
3. Click "Restore"
4. Confirm restore

### Via Supabase CLI
```bash
# List available backups
supabase db backups list

# Restore from backup
supabase db restore <backup-id>
```

## Restore from SQL Dump

### Full Database Restore
```bash
# Restore from SQL file
psql -h db.your-project.supabase.co -U postgres -d postgres -f backup.sql

# Restore from compressed dump
pg_restore -h db.your-project.supabase.co -U postgres -d postgres -F c backup.dump
```

### Partial Restore (Specific Tables)
```bash
# Restore specific tables
pg_restore -h db.your-project.supabase.co -U postgres -d postgres -t tournaments -t matches backup.dump
```

## Point-in-Time Recovery

### Using Supabase PITR
1. Go to Supabase Dashboard → Database → Backups
2. Select "Point-in-Time Recovery"
3. Choose recovery point
4. Restore to new database or overwrite existing

## Disaster Recovery Scenarios

### Scenario 1: Accidental Data Deletion
1. **Stop writes immediately** (disable API if needed)
2. Identify deletion time
3. Restore from backup before deletion
4. Verify data integrity
5. Resume operations

### Scenario 2: Database Corruption
1. **Stop all operations**
2. Restore from latest backup
3. Verify database integrity
4. Test critical queries
5. Resume operations gradually

### Scenario 3: Complete Database Failure
1. **Activate disaster recovery plan**
2. Restore from latest backup to new database
3. Update connection strings
4. Verify all services
5. Resume operations

## Testing Restore Procedures

### Monthly Test Restore
```bash
# Create test database
createdb test_restore_db

# Restore backup to test database
pg_restore -d test_restore_db backup.dump

# Verify restore
psql -d test_restore_db -c "SELECT COUNT(*) FROM tournaments;"

# Cleanup
dropdb test_restore_db
```

## Recovery Time Objectives (RTO)

- **RTO Target:** < 1 hour for critical data
- **RTO Maximum:** < 4 hours for full restore

## Recovery Point Objectives (RPO)

- **RPO Target:** < 1 hour data loss
- **RPO Maximum:** < 24 hours data loss (daily backups)

## Post-Restore Checklist

- [ ] Verify database integrity
- [ ] Test critical queries
- [ ] Verify application functionality
- [ ] Check data consistency
- [ ] Monitor performance
- [ ] Update documentation

