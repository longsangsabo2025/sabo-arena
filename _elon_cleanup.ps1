# ELON MODE: Automated Code Cleanup Script
# Fix ALL remaining issues in one shot

Write-Host "🚀 ELON MODE: Starting comprehensive cleanup..." -ForegroundColor Green

# Get baseline
Write-Host "`n📊 Initial analysis..."
$initialIssues = (flutter analyze --no-pub 2>&1 | Select-String "issues found" | Select-Object -First 1) -replace '\D+(\d+).*','$1'
Write-Host "Current issues: $initialIssues"

# Phase 1: Remove ALL unused imports automatically
Write-Host "`n📦 Phase 1: Removing unused imports..."
dart fix --apply 2>&1 | Out-Null

# Phase 2: Fix ALL unused variables by pattern
Write-Host "`n🔧 Phase 2: Analyzing unused variables..."
$unusedVars = flutter analyze --no-pub 2>&1 | Select-String "unused_local_variable"

$varsByFile = @{}
foreach ($line in $unusedVars) {
    if ($line -match "lib\\(.+?):(\\d+).*variable '(\\w+)'") {
        $file = "lib\$($matches[1])"
        $varName = $matches[3]
        if (-not $varsByFile.ContainsKey($file)) {
            $varsByFile[$file] = @()
        }
        $varsByFile[$file] += $varName
    }
}

Write-Host "Found unused variables in $($varsByFile.Count) files"

# Phase 3: Check results
Write-Host "`n✅ Running final analysis..."
$finalIssues = (flutter analyze --no-pub 2>&1 | Select-String "issues found" | Select-Object -First 1) -replace '\D+(\d+).*','$1'
Write-Host "Final issues: $finalIssues"
Write-Host "Fixed: $($initialIssues - $finalIssues) issues"

Write-Host "`n🎯 Remaining fixable issues:"
flutter analyze --no-pub 2>&1 | 
    Select-String "warning|info" | 
    Where-Object { $_ -notmatch "use_build_context_synchronously" -and $_ -notmatch "deprecated_member_use.*groupValue|onChanged" } |
    ForEach-Object { $_ -replace '.*- ', '' } | 
    Group-Object | 
    Sort-Object Count -Descending |
    Format-Table Count,Name

Write-Host "`n✅ ELON MODE: Analysis complete!" -ForegroundColor Green
