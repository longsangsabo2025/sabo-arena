$reportPath = "dead_files_report.txt"
$archiveDir = "_ARCHIVE_2025_CLEANUP"

if (-not (Test-Path $reportPath)) {
    Write-Host "Error: Report file not found at $reportPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
    Write-Host "Created archive directory: $archiveDir" -ForegroundColor Green
}

$files = Get-Content $reportPath
$count = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        $destPath = Join-Path $archiveDir $file
        $destDir = Split-Path $destPath
        
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Move-Item -Path $file -Destination $destPath -Force
        Write-Host "Archived: $file" -ForegroundColor Gray
        $count++
    }
}

Write-Host "Done. Archived $count files to $archiveDir." -ForegroundColor Cyan
Write-Host "If the app still builds, DELETE this folder." -ForegroundColor Yellow
