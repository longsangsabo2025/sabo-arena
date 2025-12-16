# 🚀 ELON MUSK CLEANUP SCRIPT
# Automatically replace print() and debugPrint() with ProductionLogger
# Run from project root: .\_flutter_scripts\cleanup_print_statements.ps1

Write-Host "🚀 ELON MODE: Cleaning up print statements..." -ForegroundColor Cyan

$libPath = "lib"
$totalReplaced = 0
$filesModified = 0

# Files to skip (already using ProductionLogger correctly)
$skipFiles = @(
    "production_logger.dart",
    "app_logger.dart",
    "dev_error_handler.dart",
    "longsang_error_reporter.dart"
)

# Get all Dart files
$dartFiles = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    # Skip logger files
    $shouldSkip = $false
    foreach ($skip in $skipFiles) {
        if ($file.Name -eq $skip) {
            $shouldSkip = $true
            break
        }
    }
    if ($shouldSkip) { continue }

    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileReplaced = 0

    # Pattern 1: Simple print('...')
    # Replace with ProductionLogger.debug('...')
    $pattern1 = "print\('([^']+)'\);"
    $replacement1 = "// REMOVED: print statement - use ProductionLogger instead"
    
    # Pattern 2: print("...")
    $pattern2 = 'print\("([^"]+)"\);'
    
    # Pattern 3: debugPrint('...')
    $pattern3 = "debugPrint\('([^']+)'\);"
    
    # Pattern 4: debugPrint("...")
    $pattern4 = 'debugPrint\("([^"]+)"\);'

    # Count matches before replacement
    $matches1 = [regex]::Matches($content, $pattern1)
    $matches2 = [regex]::Matches($content, $pattern2)
    $matches3 = [regex]::Matches($content, $pattern3)
    $matches4 = [regex]::Matches($content, $pattern4)
    
    $fileReplaced = $matches1.Count + $matches2.Count + $matches3.Count + $matches4.Count

    if ($fileReplaced -gt 0) {
        # Comment out print statements (safer than deleting)
        $content = $content -replace "(\s*)print\(", '$1// print('
        $content = $content -replace "(\s*)debugPrint\(", '$1// debugPrint('
        
        # Save file
        Set-Content -Path $file.FullName -Value $content -NoNewline
        
        $totalReplaced += $fileReplaced
        $filesModified++
        
        Write-Host "  ✅ $($file.Name): $fileReplaced statements commented" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎉 CLEANUP COMPLETE!" -ForegroundColor Cyan
Write-Host "   Files modified: $filesModified" -ForegroundColor Yellow
Write-Host "   Statements commented: $totalReplaced" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  NEXT STEPS:" -ForegroundColor Magenta
Write-Host "   1. Review commented lines" -ForegroundColor White
Write-Host "   2. Replace important logs with ProductionLogger" -ForegroundColor White
Write-Host "   3. Delete unnecessary commented lines" -ForegroundColor White


