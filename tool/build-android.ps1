param([switch]$Release)
. "$PSScriptRoot/environment.ps1"
if (-not $env:ANDROID_HOME) { throw 'Android SDK missing. Run bootstrap.ps1 -AndroidSdk D:/path/to/android-sdk.' }
if ($Release -and -not (Test-Path -LiteralPath "$projectRoot/android/key.properties")) {
    throw 'Release requires your private android/key.properties and keystore. Debug is available without release credentials.'
}
Push-Location $projectRoot
try {
    $mode = if ($Release) { '--release' } else { '--debug' }
    & $flutterExecutable build apk $mode --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
} finally { Pop-Location }
