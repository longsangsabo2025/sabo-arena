#!/usr/bin/env pwsh
# SABO Arena Database Migration Organizer

Write-Host "`n🗄️  SABO Arena Database Migration Organizer" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor DarkGray

$appRoot = "d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app"
$migrationsRoot = "$appRoot\migrations_organized"

# Migration categorization mapping
$migrationCategories = @{
    "01_schema_changes" = @{
        patterns = @("add_*_column*.sql", "create_*_table*.sql", "create_*_bucket*.sql", "create_club_*.sql", "create_share_*.sql")
        description = "Schema modifications: columns, tables, buckets"
    }
    "02_rls_policies" = @{
        patterns = @("fix_*_rls*.sql", "*_rls_policies*.sql", "manual_deploy_smart_rls.sql")
        description = "Row-level security policy fixes"
    }
    "03_functions_triggers" = @{
        patterns = @("create_*_function*.sql", "setup_*.sql", "fix_*_trigger*.sql", "update_get_*.sql", "fix_tournament_started_trigger.sql")
        description = "Database functions and triggers"
    }
    "04_data_integrity" = @{
        patterns = @("fix_*_fk.sql", "fix_*_constraint*.sql", "fix_*_relationship.sql", "fix_*_enum.sql", "migration_*.sql")
        description = "Data integrity: foreign keys, constraints"
    }
    "05_feature_additions" = @{
        patterns = @("*.sql")  # Catch-all for supabase_migrations
        description = "Feature-specific migrations"
    }
}

$stats = @{
    total = 0
    organized = 0
    skipped = 0
}

# Process sql_migrations directory
Write-Host "`n📦 Processing sql_migrations directory..." -ForegroundColor Cyan
$sqlMigrations = Get-ChildItem -Path "$appRoot\sql_migrations" -Filter "*.sql" -File

foreach ($file in $sqlMigrations) {
    $stats.total++
    $categorized = $false
    
    # Try to match against each category
    foreach ($category in $migrationCategories.Keys | Sort-Object) {
        if ($category -eq "05_feature_additions") { continue }  # Skip for sql_migrations
        
        foreach ($pattern in $migrationCategories[$category].patterns) {
            if ($file.Name -like $pattern) {
                $destination = "$migrationsRoot\$category\$($file.Name)"
                Copy-Item -Path $file.FullName -Destination $destination -Force
                Write-Host "  ✓ $($file.Name) → $category" -ForegroundColor Green
                $stats.organized++
                $categorized = $true
                break
            }
        }
        if ($categorized) { break }
    }
    
    # If not categorized, put in schema_changes as default
    if (-not $categorized) {
        $destination = "$migrationsRoot\01_schema_changes\$($file.Name)"
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Write-Host "  ⚠️  $($file.Name) → 01_schema_changes (default)" -ForegroundColor Yellow
        $stats.organized++
    }
}

# Process supabase_migrations directory
Write-Host "`n📦 Processing supabase_migrations directory..." -ForegroundColor Cyan
$supabaseMigrations = Get-ChildItem -Path "$appRoot\supabase_migrations" -Filter "*.sql" -File

foreach ($file in $supabaseMigrations) {
    $stats.total++
    $destination = "$migrationsRoot\05_feature_additions\$($file.Name)"
    Copy-Item -Path $file.FullName -Destination $destination -Force
    Write-Host "  ✓ $($file.Name) → 05_feature_additions" -ForegroundColor Green
    $stats.organized++
}

# Generate category README files
Write-Host "`n📝 Generating README files for each category..." -ForegroundColor Cyan

foreach ($category in $migrationCategories.Keys | Sort-Object) {
    $readmePath = "$migrationsRoot\$category\README.md"
    $fileCount = (Get-ChildItem -Path "$migrationsRoot\$category" -Filter "*.sql" -File).Count
    
    $readmeContent = @"
# $category

## Description
$($migrationCategories[$category].description)

## Files in this category
**Total:** $fileCount migration files

## Migrations

"@
    
    # List all SQL files
    Get-ChildItem -Path "$migrationsRoot\$category" -Filter "*.sql" -File | Sort-Object Name | ForEach-Object {
        $readmeContent += "- ``$($_.Name)```n"
    }
    
    $readmeContent += @"

## How to Apply

``````bash
# Review migration before applying
cat $category/<migration-file>.sql

# Apply to database (using psql or Supabase CLI)
psql -U postgres -d sabo_arena -f <migration-file>.sql

# Or using Supabase CLI
supabase db push <migration-file>.sql
``````

## Rollback Strategy

⚠️ **Important:** Always test in development environment first!

- Create backups before applying migrations
- Document rollback SQL for each migration
- Test rollback procedures

---
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Force
    Write-Host "  ✓ Created README for $category" -ForegroundColor Green
}

# Generate master index
Write-Host "`n📝 Generating master migration index..." -ForegroundColor Cyan

$indexContent = @"
# SABO Arena Database Migrations - Master Index

**Total Migrations:** $($stats.total)

## Migration Categories

"@

foreach ($category in $migrationCategories.Keys | Sort-Object) {
    $fileCount = (Get-ChildItem -Path "$migrationsRoot\$category" -Filter "*.sql" -File).Count
    $indexContent += @"

### $category ($fileCount files)
$($migrationCategories[$category].description)

[View Details](./$category/README.md)

"@
}

$indexContent += @"

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
Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

Set-Content -Path "$migrationsRoot\README.md" -Value $indexContent -Force
Write-Host "  ✓ Created master migration index" -ForegroundColor Green

# Summary report
Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
Write-Host "📊 MIGRATION ORGANIZATION SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray

foreach ($category in $migrationCategories.Keys | Sort-Object) {
    $count = (Get-ChildItem -Path "$migrationsRoot\$category" -Filter "*.sql" -File).Count
    Write-Host "  $category`: $count files" -ForegroundColor Yellow
}

Write-Host "`n📈 Statistics:" -ForegroundColor Cyan
Write-Host "  Total migrations: $($stats.total)" -ForegroundColor White
Write-Host "  Successfully organized: $($stats.organized)" -ForegroundColor Green
Write-Host "  Skipped: $($stats.skipped)" -ForegroundColor Gray

Write-Host "`n✅ Migration organization complete!`n" -ForegroundColor Green
Write-Host "📁 Location: migrations_organized/" -ForegroundColor Cyan
Write-Host "📖 See migrations_organized/README.md for details`n" -ForegroundColor Cyan
