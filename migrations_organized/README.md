# SABO Arena Database Migrations - Master Index

**Total Migrations:** 58

## Migration Categories

### 01_schema_changes (25 files)
Schema modifications: columns, tables, buckets

[View Details](./01_schema_changes/README.md)

### 02_rls_policies (6 files)
Row-level security policy fixes

[View Details](./02_rls_policies/README.md)

### 03_functions_triggers (7 files)
Database functions and triggers

[View Details](./03_functions_triggers/README.md)

### 04_data_integrity (10 files)
Data integrity: foreign keys, constraints

[View Details](./04_data_integrity/README.md)

### 05_feature_additions (10 files)
Feature-specific migrations

[View Details](./05_feature_additions/README.md)

## Migration Workflow

### 1. Review
Review migration files in each category to understand changes

### 2. Test
Test migrations in development environment

### 3. Apply
Apply migrations in order:
1. Schema Changes
2. RLS Policies
3. Functions & Triggers
4. Data Integrity
5. Feature Additions

### 4. Verify
Verify that migrations applied successfully

## Important Notes

⚠️ **Always backup your database before applying migrations**
⚠️ **Test in development environment first**
⚠️ **Review migration dependencies**

## Migration Status Tracking

Create a spreadsheet or document to track:
- Migration file name
- Applied date
- Applied by
- Environment (dev/staging/production)
- Status (pending/applied/rolled back)
- Notes

---
Last Updated: 2025-11-22 21:25:26
