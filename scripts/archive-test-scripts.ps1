#!/usr/bin/env pwsh
# SABO Arena Test Scripts Archival System
# Organizes 900+ test scripts into categorized archive

Write-Host "`n🎯 SABO Arena Test Scripts Archival System" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor DarkGray

$appRoot = "d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app"
$archiveBase = "$appRoot\_ARCHIVED_SCRIPTS"

# Script categorization patterns
$categories = @{
    "test-scripts" = @("test_*.py", "*_test.py")
    "check-scripts" = @("check_*.py")
    "debug-scripts" = @("debug_*.py")
    "fix-scripts" = @("fix_*.py", "*_fix.py")
    "deploy-scripts" = @("deploy_*.py", "auto_deploy_*.py")
    "verification-scripts" = @("verify_*.py", "validate_*.py")
    "analysis-scripts" = @("analyze_*.py", "audit_*.py", "comprehensive_*.py")
    "database-migrations" = @("*_migration*.py", "add_*_column*.py", "create_*_table*.py", "setup_*.py", "apply_*.py")
}

$stats = @{
    total = 0
    archived = 0
    skipped = 0
    errors = 0
}

function Move-ScriptToCategory {
    param($file, $category)
    
    try {
        $destination = "$archiveBase\$category\$($file.Name)"
        if (Test-Path $destination) {
            Write-Host "  ⚠️  Already exists: $($file.Name)" -ForegroundColor Yellow
            $stats.skipped++
        } else {
            Move-Item -Path $file.FullName -Destination $destination -Force
            Write-Host "  ✓ Archived: $($file.Name) → $category" -ForegroundColor Green
            $stats.archived++
        }
    } catch {
        Write-Host "  ❌ Error archiving $($file.Name): $_" -ForegroundColor Red
        $stats.errors++
    }
}

# Process root-level scripts
Write-Host "`n📦 Processing root-level scripts..." -ForegroundColor Cyan
$rootScripts = Get-ChildItem -Path $appRoot -Filter "*.py" -File | Where-Object { 
    $_.Name -notmatch "^(pubspec|analysis_options)" 
}

foreach ($file in $rootScripts) {
    $stats.total++
    $categorized = $false
    
    foreach ($category in $categories.Keys) {
        foreach ($pattern in $categories[$category]) {
            if ($file.Name -like $pattern) {
                Move-ScriptToCategory -file $file -category $category
                $categorized = $true
                break
            }
        }
        if ($categorized) { break }
    }
    
    # Default category for uncategorized scripts
    if (-not $categorized) {
        Move-ScriptToCategory -file $file -category "test-scripts"
    }
}

# Consolidate existing archives
Write-Host "`n📦 Consolidating scripts_archive..." -ForegroundColor Cyan
$scriptsArchive = "$appRoot\scripts_archive"
if (Test-Path $scriptsArchive) {
    $archiveScripts = Get-ChildItem -Path $scriptsArchive -Filter "*.py" -File
    
    foreach ($file in $archiveScripts) {
        $stats.total++
        $categorized = $false
        
        foreach ($category in $categories.Keys) {
            foreach ($pattern in $categories[$category]) {
                if ($file.Name -like $pattern) {
                    Move-ScriptToCategory -file $file -category $category
                    $categorized = $true
                    break
                }
            }
            if ($categorized) { break }
        }
        
        if (-not $categorized) {
            Move-ScriptToCategory -file $file -category "test-scripts"
        }
    }
    
    # Remove empty scripts_archive directory
    if ((Get-ChildItem -Path $scriptsArchive -File).Count -eq 0) {
        Remove-Item -Path $scriptsArchive -Recurse -Force
        Write-Host "  🗑️  Removed empty scripts_archive directory" -ForegroundColor Gray
    }
}

# Consolidate _SCRIPTS_ORGANIZED
Write-Host "`n📦 Consolidating _SCRIPTS_ORGANIZED..." -ForegroundColor Cyan
$scriptsOrganized = "$appRoot\_SCRIPTS_ORGANIZED"
if (Test-Path $scriptsOrganized) {
    $organizedScripts = Get-ChildItem -Path $scriptsOrganized -Filter "*.py" -File -Recurse
    
    foreach ($file in $organizedScripts) {
        $stats.total++
        $categorized = $false
        
        foreach ($category in $categories.Keys) {
            foreach ($pattern in $categories[$category]) {
                if ($file.Name -like $pattern) {
                    Move-ScriptToCategory -file $file -category $category
                    $categorized = $true
                    break
                }
            }
            if ($categorized) { break }
        }
        
        if (-not $categorized) {
            Move-ScriptToCategory -file $file -category "analysis-scripts"
        }
    }
    
    # Remove empty _SCRIPTS_ORGANIZED directory
    if ((Get-ChildItem -Path $scriptsOrganized -File -Recurse).Count -eq 0) {
        Remove-Item -Path $scriptsOrganized -Recurse -Force
        Write-Host "  🗑️  Removed empty _SCRIPTS_ORGANIZED directory" -ForegroundColor Gray
    }
}

# Consolidate old archive directories
Write-Host "`n📦 Consolidating old archive directories..." -ForegroundColor Cyan
$oldArchives = @(
    "$appRoot\_archive_20251023_104534",
    "$appRoot\_archive_20251023_105328"
)

foreach ($oldArchive in $oldArchives) {
    if (Test-Path $oldArchive) {
        $oldScripts = Get-ChildItem -Path $oldArchive -Filter "*.py" -File -Recurse
        
        foreach ($file in $oldScripts) {
            $stats.total++
            Move-ScriptToCategory -file $file -category "test-scripts"
        }
        
        # Remove empty old archive
        if ((Get-ChildItem -Path $oldArchive -File -Recurse).Count -eq 0) {
            Remove-Item -Path $oldArchive -Recurse -Force
            Write-Host "  🗑️  Removed empty archive: $(Split-Path $oldArchive -Leaf)" -ForegroundColor Gray
        }
    }
}

# Generate summary report
Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
Write-Host "📊 ARCHIVAL SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray

foreach ($category in $categories.Keys | Sort-Object) {
    $count = (Get-ChildItem -Path "$archiveBase\$category" -Filter "*.py" -File -ErrorAction SilentlyContinue).Count
    if ($count -gt 0) {
        Write-Host "  $category`: $count scripts" -ForegroundColor Yellow
    }
}

Write-Host "`n📈 Statistics:" -ForegroundColor Cyan
Write-Host "  Total processed: $($stats.total)" -ForegroundColor White
Write-Host "  Successfully archived: $($stats.archived)" -ForegroundColor Green
Write-Host "  Skipped (duplicates): $($stats.skipped)" -ForegroundColor Yellow
Write-Host "  Errors: $($stats.errors)" -ForegroundColor $(if ($stats.errors -gt 0) { "Red" } else { "Gray" })

Write-Host "`n✅ Script archival complete!`n" -ForegroundColor Green
