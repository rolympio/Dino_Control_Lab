param([string]$FlutterSdk, [string]$AndroidSdk)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localConfig = Join-Path $projectRoot '.dino-toolchain.json'
$saved = if (Test-Path -LiteralPath $localConfig) { Get-Content -LiteralPath $localConfig -Raw | ConvertFrom-Json } else { $null }
$flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
$fromPath = if ($flutterCommand) { Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent } else { $null }
$candidates = @($FlutterSdk, $env:FLUTTER_ROOT, $saved.FlutterSdk, $fromPath, 'D:/toolchains/flutter')
$resolvedFlutter = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'bin/flutter.bat')) } | Select-Object -First 1
if (-not $resolvedFlutter) { throw 'Flutter SDK not found. Run tool/bootstrap.ps1 -FlutterSdk D:/path/to/flutter -AndroidSdk D:/path/to/android-sdk.' }
$env:FLUTTER_ROOT = [IO.Path]::GetFullPath($resolvedFlutter)
$env:Path = "$env:FLUTTER_ROOT/bin;$env:Path"
$resolvedAndroid = @($AndroidSdk, $env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, $saved.AndroidSdk, 'D:/toolchains/android') |
    Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'platform-tools/adb.exe')) } | Select-Object -First 1
if ($resolvedAndroid) { $env:ANDROID_HOME = [IO.Path]::GetFullPath($resolvedAndroid) }
if (-not $env:JAVA_HOME) {
    $javaCommand = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaCommand) { $env:JAVA_HOME = Split-Path (Split-Path $javaCommand.Source -Parent) -Parent }
}
if (-not $env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME = 'D:/toolchains/gradle-cache' }
# Scope this to the script process; Web/Android do not need Windows plugin symlinks.
$env:FLUTTER_WINDOWS = 'false'
$flutterExecutable = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'
