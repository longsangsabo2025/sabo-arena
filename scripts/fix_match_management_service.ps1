# Fix match_management_service.dart - Replace incorrect API calls
# This fixes the linter errors by using correct ProductionLogger and StandardizedErrorHandler APIs

$file = "lib/services/match_management_service.dart"
$content = Get-Content $file -Raw

# Fix ProductionLogger.debug calls with data parameter
$content = $content -replace "ProductionLogger\.debug\(\s*'([^']+)',\s*tag:\s*'([^']+)',\s*data:\s*\{([^}]+)\}\s*\);", "ProductionLogger.debug('`$1', tag: '`$2');"

# Fix ProductionLogger.info calls with data parameter  
$content = $content -replace "ProductionLogger\.info\(\s*'([^']+)',\s*tag:\s*'([^']+)',\s*data:\s*\{([^}]+)\}\s*\);", "ProductionLogger.info('`$1', tag: '`$2');"

# Fix StandardizedErrorHandler.handleError calls - remove stackTrace and userMessage parameters
$content = $content -replace "StandardizedErrorHandler\.handleError\(\s*`$e,\s*context:\s*ErrorContext\(([^)]+)\),\s*stackTrace:\s*stackTrace,\s*\);", "StandardizedErrorHandler.handleError(`$e, context: ErrorContext(`$1));"

# Fix ErrorContext - change userMessage to context
$content = $content -replace "userMessage:\s*'([^']+)'", "context: '`$1'"

Set-Content -Path $file -Value $content -NoNewline
Write-Host "✅ Fixed match_management_service.dart" -ForegroundColor Green

