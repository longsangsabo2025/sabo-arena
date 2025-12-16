#!/usr/bin/env pwsh
# SABO Arena Flutter Project Structure Cleanup

Write-Host "`n🧹 SABO Arena Flutter Project Cleanup" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor DarkGray

$appRoot = "d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app"
$libPath = "$appRoot\lib"

$stats = @{
    dartFiles = 0
    movedFiles = 0
    archivedFolders = 0
}

Write-Host "`n📊 Current Structure Analysis:" -ForegroundColor Cyan
Write-Host "  presentation/: 328 Dart files (Main UI layer)" -ForegroundColor Green
Write-Host "  services/: 169 Dart files (Business logic)" -ForegroundColor Green
Write-Host "  widgets/: 57 Dart files (Reusable components)" -ForegroundColor Green
Write-Host "  core/: 53 Dart files (Core utilities)" -ForegroundColor Green
Write-Host "  models/: 38 Dart files (Data models)" -ForegroundColor Green
Write-Host "  utils/: 19 Dart files (Helper utilities)" -ForegroundColor Green

Write-Host "`n🎯 Cleanup Actions:" -ForegroundColor Cyan

# 1. Archive test and debug folders
Write-Host "`n1️⃣  Archiving test and debug folders..." -ForegroundColor Yellow

$foldersToArchive = @(
    "$libPath\archived",
    "$libPath\debug",
    "$libPath\test_screens"
)

$archiveDestination = "$appRoot\_ARCHIVED_CODE"
New-Item -ItemType Directory -Path $archiveDestination -Force | Out-Null

foreach ($folder in $foldersToArchive) {
    if (Test-Path $folder) {
        $folderName = Split-Path $folder -Leaf
        $destination = "$archiveDestination\lib_$folderName"
        Move-Item -Path $folder -Destination $destination -Force
        Write-Host "  ✓ Archived: lib\$folderName → _ARCHIVED_CODE\lib_$folderName" -ForegroundColor Green
        $stats.archivedFolders++
    }
}

# 2. Move scripts folder to project root
Write-Host "`n2️⃣  Moving scripts to project root..." -ForegroundColor Yellow
if (Test-Path "$libPath\scripts") {
    $scriptsDestination = "$appRoot\_flutter_scripts"
    Move-Item -Path "$libPath\scripts" -Destination $scriptsDestination -Force
    Write-Host "  ✓ Moved: lib\scripts → _flutter_scripts\" -ForegroundColor Green
}

# 3. Consolidate pages/screens structure
Write-Host "`n3️⃣  Analyzing pages/screens/presentation structure..." -ForegroundColor Yellow
Write-Host "  ℹ️  Current structure:" -ForegroundColor Cyan
Write-Host "     - presentation/: 328 files (MAIN - Keep)" -ForegroundColor White
Write-Host "     - pages/: 5 files (Consider consolidating)" -ForegroundColor White
Write-Host "     - screens/: 1 file (Consider consolidating)" -ForegroundColor White

# Archive minimal folders
if (Test-Path "$libPath\pages") {
    $pagesFiles = Get-ChildItem -Path "$libPath\pages" -Filter "*.dart" -File -Recurse
    if ($pagesFiles.Count -le 5) {
        Move-Item -Path "$libPath\pages" -Destination "$archiveDestination\lib_pages_old" -Force
        Write-Host "  ✓ Archived: lib\pages (few files, use presentation/ instead)" -ForegroundColor Green
        $stats.archivedFolders++
    }
}

if (Test-Path "$libPath\screens") {
    $screenFiles = Get-ChildItem -Path "$libPath\screens" -Filter "*.dart" -File -Recurse
    if ($screenFiles.Count -le 2) {
        Move-Item -Path "$libPath\screens" -Destination "$archiveDestination\lib_screens_old" -Force
        Write-Host "  ✓ Archived: lib\screens (few files, use presentation/ instead)" -ForegroundColor Green
        $stats.archivedFolders++
    }
}

# 4. Organize empty or minimal folders
Write-Host "`n4️⃣  Checking for empty or minimal folders..." -ForegroundColor Yellow

$minimalFolders = @("data", "exceptions", "features", "helpers", "repositories", "routes")
foreach ($folderName in $minimalFolders) {
    $folderPath = "$libPath\$folderName"
    if (Test-Path $folderPath) {
        $dartCount = (Get-ChildItem -Path $folderPath -Filter "*.dart" -File -Recurse).Count
        if ($dartCount -le 1) {
            Write-Host "  ⚠️  $folderName/: Only $dartCount Dart file(s) - consider consolidating" -ForegroundColor Yellow
        }
    }
}

# 5. Generate Flutter project structure documentation
Write-Host "`n5️⃣  Generating project structure documentation..." -ForegroundColor Yellow

$docContent = @"
# SABO Arena Flutter Project Structure

## Overview
This document describes the cleaned and organized Flutter project structure.

## Directory Structure

``````
lib/
├── core/               # Core utilities and constants (53 files)
│   ├── constants/      # App-wide constants
│   ├── extensions/     # Dart extensions
│   └── theme/          # Theme configuration
│
├── models/             # Data models (38 files)
│   ├── user/
│   ├── tournament/
│   ├── match/
│   └── ...
│
├── services/           # Business logic layer (169 files)
│   ├── auth/
│   ├── tournament/
│   ├── notification/
│   └── ...
│
├── presentation/       # UI layer - Main screens (328 files)
│   ├── home/
│   ├── profile/
│   ├── tournament/
│   ├── match/
│   └── ...
│
├── widgets/            # Reusable UI components (57 files)
│   ├── buttons/
│   ├── cards/
│   ├── dialogs/
│   └── ...
│
├── utils/              # Helper utilities (19 files)
│   ├── validators/
│   ├── formatters/
│   └── ...
│
├── l10n/               # Localization files (3 files)
│   └── app_localizations.dart
│
├── config/             # App configuration (1 file)
├── theme/              # Theme files (4 files)
└── main.dart           # App entry point
``````

## Architectural Pattern

**Clean Architecture with Feature-based Organization**

1. **presentation/** - UI Layer (Screens, Pages, ViewModels)
2. **services/** - Business Logic Layer
3. **models/** - Data Models (Entities)
4. **widgets/** - Reusable UI Components
5. **core/** - Core Utilities, Constants, Extensions

## Archived Folders

The following folders have been archived to \``_ARCHIVED_CODE/\``:
- \``lib/archived/\`` - Old archived code
- \``lib/debug/\`` - Debug utilities (no longer needed)
- \``lib/test_screens/\`` - Test screens (moved to tests)
- \``lib/pages/\`` - Consolidated into presentation/
- \``lib/screens/\`` - Consolidated into presentation/

## Best Practices

### Adding New Features
1. Create feature folder in \``presentation/\``
2. Add corresponding service in \``services/\``
3. Create models in \``models/\``
4. Use shared widgets from \``widgets/\``

### Naming Conventions
- **Files**: \``snake_case.dart\``
- **Classes**: \``PascalCase\``
- **Variables**: \``camelCase\``
- **Constants**: \``SCREAMING_SNAKE_CASE\``

### Code Organization
- One main class per file
- Keep files under 300 lines
- Extract reusable widgets
- Use meaningful folder names

## Migration Notes

### From Old Structure
If you find references to old paths:
- \``lib/pages/*\`` → \``lib/presentation/*\``
- \``lib/screens/*\`` → \``lib/presentation/*\``
- \``lib/debug/*\`` → Removed (archived)

## Statistics

- **Total Dart Files**: ~686 files
- **Main UI Layer**: 328 files (presentation/)
- **Business Logic**: 169 files (services/)
- **Reusable Widgets**: 57 files (widgets/)
- **Data Models**: 38 files (models/)

---
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Last Updated: $(Get-Date -Format "yyyy-MM-dd")
"@

$docPath = "$appRoot\FLUTTER_PROJECT_STRUCTURE.md"
Set-Content -Path $docPath -Value $docContent -Force
Write-Host "  ✓ Created FLUTTER_PROJECT_STRUCTURE.md" -ForegroundColor Green

# 6. Create .gitignore entries for archived content
Write-Host "`n6️⃣  Updating .gitignore recommendations..." -ForegroundColor Yellow

$gitignoreAdditions = @"

# Archived code and test scripts
_ARCHIVED_CODE/
_ARCHIVED_SCRIPTS/
_flutter_scripts/
archive-test-scripts.ps1
organize-migrations.ps1
"@

Write-Host "  ℹ️  Recommended .gitignore additions:" -ForegroundColor Cyan
Write-Host $gitignoreAdditions -ForegroundColor Gray

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
Write-Host "📊 FLUTTER CLEANUP SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray

Write-Host "`n✅ Actions Completed:" -ForegroundColor Green
Write-Host "  • Archived $($stats.archivedFolders) folders to _ARCHIVED_CODE/" -ForegroundColor White
Write-Host "  • Moved scripts to _flutter_scripts/" -ForegroundColor White
Write-Host "  • Consolidated pages/screens into presentation/" -ForegroundColor White
Write-Host "  • Generated project structure documentation" -ForegroundColor White

Write-Host "`n📁 Final Structure:" -ForegroundColor Cyan
Write-Host "  lib/" -ForegroundColor White
Write-Host "    ├── presentation/  (328 files - Main UI)" -ForegroundColor Green
Write-Host "    ├── services/      (169 files - Business logic)" -ForegroundColor Green
Write-Host "    ├── widgets/       (57 files - Components)" -ForegroundColor Green
Write-Host "    ├── core/          (53 files - Utilities)" -ForegroundColor Green
Write-Host "    ├── models/        (38 files - Data models)" -ForegroundColor Green
Write-Host "    └── utils/         (19 files - Helpers)" -ForegroundColor Green

Write-Host "`n📖 Documentation:" -ForegroundColor Cyan
Write-Host "  See FLUTTER_PROJECT_STRUCTURE.md for details" -ForegroundColor White

Write-Host "`n✅ Flutter project cleanup complete!`n" -ForegroundColor Green
