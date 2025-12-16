# Database Backup Procedures

## Automated Backup Configuration

### Daily Full Backups
- **Schedule:** Every day at 2:00 AM UTC
- **Retention:** 30 days
- **Location:** Supabase automated backups + S3 backup

### Hourly Incremental Backups
- **Schedule:** Every hour
- **Retention:** 7 days
- **Location:** Supabase automated backups

### Weekly Full Backups
- **Schedule:** Every Sunday at 2:00 AM UTC
- **Retention:** 12 weeks
- **Location:** S3 backup

### Monthly Full Backups
- **Schedule:** First day of month at 2:00 AM UTC
- **Retention:** 12 months
- **Location:** S3 backup + cold storage

## Manual Backup Commands

### Supabase CLI Backup
```bash
# Full database backup
supabase db dump -f backup_$(date +%Y%m%d_%H%M%S).sql

# Backup specific tables
supabase db dump -t tournaments -t matches -f tournaments_backup.sql
```

### PostgreSQL Direct Backup
```bash
# Full backup
pg_dump -h db.your-project.supabase.co -U postgres -d postgres -F c -f backup.dump

# Backup with compression
pg_dump -h db.your-project.supabase.co -U postgres -d postgres -F c -Z 9 -f backup.dump.gz
```

## Backup Verification

### Check Backup Integrity
```bash
# Verify backup file
pg_restore --list backup.dump | head -20

# Test restore (dry run)
pg_restore --dry-run backup.dump
```

## Restore Procedures

See `restore_procedures.md` for detailed restore steps.

## Monitoring

- Set up alerts for backup failures
- Monitor backup storage usage
- Verify backups monthly (test restore)

