# Levantamento read-only do ambiente de execucao: engines no PATH e fora dele,
# SDK Android, AVDs, navegadores, estado do repositorio e artefatos existentes.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File survey_env.ps1 -ProjectRoot <pasta> [-Json] [-DeepScan]
#
# Nada e instalado nem alterado. Cada sonda e protegida: Access Denied vira
# informacao, nao erro - o terminal do Manus costuma rodar em conta de servico
# sem rede e sem acesso ao App Data do usuario real.
param(
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$Json,
  [switch]$DeepScan
)
$ErrorActionPreference = 'SilentlyContinue'
$out = [ordered]@{}

function Probe([scriptblock]$Body) {
  # Retorna $null em erro; nunca deixa o levantamento parar no meio.
  try { & $Body } catch { $null }
}
function GitAt([string]$Root, [string[]]$GitArgs) {
  # A conta do terminal costuma ser dona diferente da pasta (dubious ownership).
  $sd = ($Root -replace '\\', '/')
  & git -c "safe.directory=$sd" -C $Root @GitArgs 2>&1
}

# --- identidade e alcance real do terminal ----------------------------------
$sidText = Probe {
  $wi = [security.principal.windowsidentity]::GetCurrent()
  $wi.User.Translate([security.principal.securityidentifier]).Value
}
$out.identity = [ordered]@{
  account = "$env:USERDOMAIN\$env:USERNAME"
  sid     = if ($sidText) { [string]$sidText } else { 'desconhecida' }
  home    = $env:USERPROFILE
  ps      = $PSVersionTable.PSVersion.ToString()
  web     = Probe { Test-Connection -ComputerName '1.1.1.1' -Count 1 -Quiet }
  appdata = Probe { @(Get-ChildItem $env:APPDATA -ErrorAction Stop).Count }
}

# --- engines no PATH ----------------------------------------------------------
$candidates = 'flutter','dart','godot','godot4','unity','node','npm','python','python3','java','gradle','adb','emulator','sdkmanager','dotnet','cargo'
$pathEngines = [ordered]@{}
foreach ($c in $candidates) {
  $cmd = Get-Command $c -ErrorAction SilentlyContinue
  if ($cmd) { $pathEngines[$c] = [string]$cmd.Source }
}
$out.path_engines = $pathEngines

# --- toolchains fora do PATH --------------------------------------------------
# PowerShell ignora diferenca de maiusculas: nunca use $deep com um switch -Deep.
$roots = @($ProjectRoot, (Split-Path $ProjectRoot -Parent), $env:USERPROFILE)
if ($DeepScan) { $roots += @((Split-Path $ProjectRoot -Qualifier), 'C:\') }
$pattern = '^(flutter|android-sdk|android_sdk|SDK|gradle-\d.*|jdk.*|openjdk.*|godot.*|Unity|\.toolchain)$'
# ignora subpastas de plataforma do proprio projeto (ios/Flutter, linux/flutter...)
$noise = '[\\/](ios|linux|macos|windows|web|android)[\\/](Flutter|flutter|ephemeral)([\\/]|$)'
$toolHits = @()
foreach ($r in ($roots | Where-Object { $_ } | Select-Object -Unique)) {
  if (-not (Test-Path -LiteralPath $r)) { continue }
  $lvl = if ($DeepScan) { 3 } else { 2 }
  foreach ($d in @(Get-ChildItem -LiteralPath $r -Directory -Recurse -Depth $lvl -Force -ErrorAction SilentlyContinue)) {
    if ([string]$d.Name -notmatch $pattern) { continue }
    $full = [string]$d.FullName
    if ($full -match $noise) { continue }
    $toolHits += $full
  }
}
$out.found_offpath = @($toolHits | Sort-Object -Unique | Select-Object -First 25)

# --- Android SDK / AVD / local.properties ------------------------------------
$sdkGuess = $env:ANDROID_HOME
if (-not $sdkGuess) { $sdkGuess = $env:ANDROID_SDK_ROOT }
if (-not $sdkGuess) { $sdkGuess = ($out.found_offpath | Where-Object { $_ -match 'android' } | Select-Object -First 1) }
$components = @(); $hasEmu = $false; $hasPt = $false; $sysImg = @(); $avds = @(); $localProps = @()
if ($sdkGuess -and (Test-Path -LiteralPath $sdkGuess)) {
  $components = @(Get-ChildItem -LiteralPath $sdkGuess -Directory -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.Name })
  $hasEmu = [bool](Test-Path -LiteralPath (Join-Path $sdkGuess 'emulator'))
  $hasPt = [bool](Test-Path -LiteralPath (Join-Path $sdkGuess 'platform-tools\adb.exe'))
  $sysImg = @(Get-ChildItem -LiteralPath (Join-Path $sdkGuess 'system-images') -Directory -Recurse -Depth 1 -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.FullName.Replace((Join-Path $sdkGuess 'system-images') + '\', '') })
}
$avdDir = Join-Path $env:USERPROFILE '.android\avd'
if (Test-Path -LiteralPath $avdDir) {
  $avds = @(Get-ChildItem -LiteralPath $avdDir -Filter '*.ini' -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.BaseName })
}
$lp = Join-Path $ProjectRoot 'android\local.properties'
if (Test-Path -LiteralPath $lp) { $localProps = @(Get-Content -LiteralPath $lp -ErrorAction SilentlyContinue) }
$out.android = [ordered]@{
  sdk_home           = if ($sdkGuess) { [string]$sdkGuess } else { 'ANDROID_HOME/ANDROID_SDK_ROOT ausentes' }
  components         = if (@($components).Count) { $components } else { @() }
  has_emulator       = $hasEmu
  has_platform_tools = $hasPt
  system_images      = @($sysImg)
  avds               = @($avds)
  local_properties   = @($localProps)
}

# --- navegadores (define se 'flutter run -d chrome' tem chance) -------------
$browselist = @()
foreach ($p in @(
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\Application\brave.exe')
)) { if ($p -and (Test-Path -LiteralPath $p)) { $browselist += [string]$p } }
$out.browsers = @($browselist | Sort-Object -Unique)

# --- repositorio: sincronia e arquivos que impedem build --------------------
$watchList = 'android\local.properties','.dart_tool','build','assets','pubspec.lock','web','windows','android\key.properties','android\settings.gradle.kts','pubspec.yaml'
$watched = @()
$gitignore = @(Probe { Get-Content (Join-Path $ProjectRoot '.gitignore') -ErrorAction Stop | Where-Object { $_ -and $_ -notmatch '^\s*#' } })
foreach ($w in $watchList) {
  $present = [bool](Test-Path -LiteralPath (Join-Path $ProjectRoot $w))
  $hit = @($gitignore | Where-Object { $_ -and ($w -like $_ -or $w -like ($_ -replace '/$', '') + '*') }).Count
  $watched += ("{0}={1}{2}" -f $w, $present, $(if ($hit) { ' [no .gitignore]' } else { '' }))
}
$out.repo = [ordered]@{
  root      = Probe { (Resolve-Path -LiteralPath $ProjectRoot).Path }
  is_git    = [bool](Test-Path (Join-Path $ProjectRoot '.git'))
  head      = Probe { GitAt $ProjectRoot @('rev-parse', '--short', 'HEAD') }
  branch    = Probe { GitAt $ProjectRoot @('branch', '--show-current') }
  remotes   = @(Probe { GitAt $ProjectRoot @('remote', '-v') })
  tracked   = Probe { @(GitAt $ProjectRoot @('ls-files')).Count }
  watched   = $watched
  gitignore = $gitignore
}

# --- artefatos compilados e idade -------------------------------------------
# Recursao ampla em build/ pode levar minutos; procure so nos lugares onde a
# engine escreve artefatos, com profundidade limitada.
$artifactDirs = @('build', 'dist', 'bin', 'export', '.')
$files = @()
foreach ($ad in $artifactDirs) {
  $full = Join-Path $ProjectRoot $ad
  if (-not (Test-Path -LiteralPath $full)) { continue }
  $files += @(Get-ChildItem -LiteralPath $full -Recurse -Depth 3 -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in '.apk', '.aab', '.exe', '.zip', '.msix', '.appimage', '.deb' -and $_.Length -gt 50000 })
}
$out.artifacts = @(
  foreach ($f in @($files | Sort-Object LastWriteTime -Descending | Select-Object -Expand FullName -Unique | Select-Object -First 12)) {
    $fi = Get-Item -LiteralPath $f -ErrorAction SilentlyContinue
    if ($fi) {
      [ordered]@{ mb = [math]::Round($fi.Length / 1MB, 1); modified = $fi.LastWriteTime.ToString('yyyy-MM-dd HH:mm'); file = [string]$fi.FullName }
    }
  }
)

# --- saida ------------------------------------------------------------------
if ($Json) { $out | ConvertTo-Json -Depth 6; exit 0 }

function Section($name, $obj) {
  Write-Host "== $name ==" -ForegroundColor Cyan
  if ($obj -is [System.Collections.IDictionary]) {
    foreach ($e in $obj.GetEnumerator()) { Write-Host ("  {0}: {1}" -f $e.Key, (@($e.Value) -join ', ')) }
  } elseif ($null -eq $obj) {
    Write-Host '  (nao determinado)'
  } elseif ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
    $arr = @($obj)
    if (-not $arr.Count) { Write-Host '  (nenhum)'; return }
    foreach ($i in $arr) {
      if ($i -is [System.Collections.IDictionary]) {
        $parts = foreach ($e in $i.GetEnumerator()) { "{0}={1}" -f $e.Key, $e.Value }
        Write-Host ('  ' + ($parts -join '  '))
      } else { Write-Host "  $i" }
    }
  } else { Write-Host "  $obj" }
}
Section 'identidade' $out.identity
Section 'engines no PATH' $out.path_engines
Section 'toolchains fora do PATH' $out.found_offpath
Section 'android' $out.android
Section 'navegadores' $out.browsers
Section 'repositorio' $out.repo
Section 'artefatos' $out.artifacts
Write-Host ''
if (-not $out.identity.web) {
  Write-Host 'web=False: sem rede neste terminal (conta de servico). Build, push e abertura real devem rodar na sessao local do usuario.' -ForegroundColor Yellow
}
if (-not $pathEngines.Contains('flutter')) {
  Write-Host 'flutter fora do PATH: se apareceu em "toolchains fora do PATH", use o caminho completo nos comandos.' -ForegroundColor Yellow
}
if (@($out.browsers).Count -eq 0) { Write-Host 'nenhum navegador: o teste web so pode ser feito pelo usuario.' -ForegroundColor Yellow }
if (-not $out.android.has_emulator) { Write-Host 'sem emulator no SDK: valide Android em aparelho real (adb) ou instale emulator + system-images.' -ForegroundColor Yellow }
Write-Host 'proximos passos: node scripts/inspect_web_bundle.js <build/web> | node scripts/inspect_apk.js <apk>' -ForegroundColor Yellow
