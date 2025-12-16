# Fix print statements in tournament_service.dart
$filePath = "lib/services/tournament_service.dart"
$content = Get-Content $filePath -Raw

# Replace simple print() calls
$content = $content -replace "print\('([^']*)'\)", "ProductionLogger.info('`$1', tag: 'TournamentService')"
$content = $content -replace 'print\("([^"]*)"\)', 'ProductionLogger.info("$1", tag: "TournamentService")'

# Replace debugPrint() calls
$content = $content -replace "debugPrint\('([^']*)'\)", "ProductionLogger.debug('`$1', tag: 'TournamentService')"
$content = $content -replace 'debugPrint\("([^"]*)"\)', 'ProductionLogger.debug("$1", tag: "TournamentService")'

# Replace multi-line print statements (simple cases)
$content = $content -replace "print\(\s*'([^']*)'\s*\)", "ProductionLogger.info('`$1', tag: 'TournamentService')"
$content = $content -replace 'print\(\s*"([^"]*)"\s*\)', 'ProductionLogger.info("$1", tag: "TournamentService")'

Set-Content $filePath -Value $content -NoNewline
Write-Host "✅ Fixed print statements in tournament_service.dart"

