param([string]$BaseHref = '/')
. "$PSScriptRoot/environment.ps1"
if ($BaseHref -notmatch '^/([^?#]*)/$' -and $BaseHref -ne '/') { throw 'BaseHref must start and end with / (example: /Dino_Control_Lab/).' }
Push-Location $projectRoot
try {
    & $flutterExecutable build web --release --no-pub --base-href $BaseHref --no-web-resources-cdn --no-wasm-dry-run
    if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }
    Compress-Archive -Path 'build/web/*' -DestinationPath 'build/dino-control-lab-web.zip' -Force
} finally { Pop-Location }
