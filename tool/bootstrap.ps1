param([string]$FlutterSdk, [string]$AndroidSdk)
. "$PSScriptRoot/environment.ps1" -FlutterSdk $FlutterSdk -AndroidSdk $AndroidSdk
$settings = @{ FlutterSdk = $env:FLUTTER_ROOT; AndroidSdk = $env:ANDROID_HOME }
$settings | ConvertTo-Json | Set-Content -LiteralPath $localConfig -Encoding UTF8
$properties = "flutter.sdk=$($env:FLUTTER_ROOT.Replace('\','/'))`n"
if ($env:ANDROID_HOME) { $properties += "sdk.dir=$($env:ANDROID_HOME.Replace('\','/'))`n" }
[IO.File]::WriteAllText((Join-Path $projectRoot 'android/local.properties'), $properties)
Push-Location $projectRoot
try {
    & $flutterExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency setup failed. See Flutter output above.' }
    Write-Host "Ready: $projectRoot"
    Write-Host 'Build web: powershell -File tool/build-web.ps1'
    Write-Host 'Serve web: powershell -File tool/serve-web.ps1'
} finally { Pop-Location }
