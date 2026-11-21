param([int]$Port = 8080, [string]$BaseHref = '/')
. "$PSScriptRoot/environment.ps1"
Push-Location $projectRoot
try {
    & "$env:FLUTTER_ROOT/bin/dart.bat" run tool/web_server.dart build/web $Port $BaseHref
    if ($LASTEXITCODE -ne 0) { throw 'Local HTTP server failed.' }
} finally { Pop-Location }
